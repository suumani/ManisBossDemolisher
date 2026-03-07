-- __ManisBossDemolisher__/scripts/use_cases/rocket_export_use_case.lua
-- ----------------------------
-- 責務:
-- - ロケット発射起点の輸出ユースケースを実行する。
-- - 判定順序を統制し、各 service/store/planner/executor を呼び分ける。
-- - generated chunk の真実源として ManisLibGeneratedChunkIndex を利用する。
-- - forbidden rect 補正後の着地点が未生成 chunk なら Skip する。
-- ----------------------------

local M = {}

local Categories = require("scripts.defines.demolisher_categories")
local Logger = require("scripts.logging.logger")

local ExportProbabilityService = require("scripts.services.export_probability_service")
local DestinationSurfaceSelector = require("scripts.services.destination_surface_selector")
local DemolisherSpeciesSelector = require("scripts.services.demolisher_species_selector")
local DemolisherCapService = require("scripts.services.demolisher_cap_service")
local DemolisherQualityService = require("scripts.services.demolisher_quality_service")
local PerimeterGeneratedChunkSelector = require("scripts.services.perimeter_generated_chunk_selector")

local GeneratedChunkIndexGateway = require("scripts.gateways.generated_chunk_index_gateway")

local DemolisherSpawnPositionPlanner = require("scripts.planners.demolisher_spawn_position_planner")
local TerritoryResolver = require("scripts.resolvers.territory_resolver")
local DemolisherSpawnExecutor = require("scripts.executors.demolisher_spawn_executor")

local BossDemolisherFlagStore = require("scripts.stores.boss_demolisher_flag_store")
local ExportWindowStore = require("scripts.stores.export_window_store")
local ExportMessageStore = require("scripts.stores.export_message_store")

local function category_key(name)
  if type(name) ~= "string" then
    return name
  end

  if name:sub(-4) == "-alt" then
    return name:sub(1, -5)
  end

  return name
end

local function to_chunk_position(position)
  return {
    x = math.floor(position.x / 32),
    y = math.floor(position.y / 32),
  }
end

local function get_segmented_unit_name(segmented_unit)
  if not segmented_unit or not segmented_unit.valid then
    return nil
  end

  local prototype = segmented_unit.prototype
  if not prototype then
    return nil
  end

  return prototype.name
end

local function count_surface_units(surface)
  local total = 0
  local fatal = 0

  local segmented_units = surface.get_segmented_units()
  for _, segmented_unit in pairs(segmented_units) do
    if segmented_unit.valid then
      total = total + 1

      local unit_name = get_segmented_unit_name(segmented_unit)
      if unit_name and Categories.FATAL[category_key(unit_name)] == true then
        fatal = fatal + 1
      end
    end
  end

  return total, fatal
end

local function count_territory_units(territory)
  local total = 0
  local fatal = 0

  local segmented_units = territory.get_segmented_units()
  for _, segmented_unit in pairs(segmented_units) do
    if segmented_unit.valid then
      total = total + 1

      local unit_name = get_segmented_unit_name(segmented_unit)
      if unit_name and Categories.FATAL[category_key(unit_name)] == true then
        fatal = fatal + 1
      end
    end
  end

  return total, fatal
end

local function get_export_message()
  return { "mani-boss-demolisher-message.boss-demolisher-exported" }
end

function M.execute(ctx)
  local trigger_surface = ctx and ctx.trigger_surface
  if not trigger_surface or not trigger_surface.valid then
    return
  end

  local source_surface_name = trigger_surface.name

  if not ExportWindowStore.can_export(source_surface_name, 5) then
    Logger.info({
      "[Export][Skip]",
      " reason=source_window_cap",
      " trigger_surface=", source_surface_name,
      " current=", ExportWindowStore.get_count(source_surface_name),
      " limit=5",
    })
    return
  end

  if not ExportProbabilityService.should_spawn(trigger_surface) then
    Logger.info({
      "[Export][Skip]",
      " reason=probability",
      " trigger_surface=", source_surface_name,
    })
    return
  end

  local dest_surface = DestinationSurfaceSelector.choose_destination_surface(ctx)
  if not dest_surface then
    Logger.info({
      "[Export][Skip]",
      " reason=no_destination_surface",
      " trigger_surface=", source_surface_name,
    })
    return
  end

  local pick = DemolisherSpeciesSelector.choose_demolisher(dest_surface)
  if not pick then
    Logger.info({
      "[Export][Skip]",
      " reason=no_demolisher_pick",
      " trigger_surface=", source_surface_name,
      " dest_surface=", dest_surface.name,
    })
    return
  end

  local player_force = game.forces.player
  local combat_cap = DemolisherCapService.get_combat_cap(player_force)
  local fatal_cap = DemolisherCapService.get_fatal_cap(player_force)

  local surface_total, surface_fatal = count_surface_units(dest_surface)
  local is_fatal_pick = (pick.category == "fatal") or (Categories.FATAL[category_key(pick.name)] == true)

  if is_fatal_pick then
    if surface_fatal >= fatal_cap then
      Logger.info({
        "[Export][Skip]",
        " reason=dest_surface_fatal_cap",
        " dest_surface=", dest_surface.name,
        " current_fatal=", surface_fatal,
        " fatal_cap=", fatal_cap,
      })
      return
    end
  else
    if surface_total >= combat_cap then
      Logger.info({
        "[Export][Skip]",
        " reason=dest_surface_combat_cap",
        " dest_surface=", dest_surface.name,
        " current_total=", surface_total,
        " combat_cap=", combat_cap,
      })
      return
    end
  end

  local generated_chunk_keys = GeneratedChunkIndexGateway.get_generated_chunk_keys(dest_surface)
  local selected_chunk = PerimeterGeneratedChunkSelector.select_chunk(generated_chunk_keys, dest_surface.name)

  local position = DemolisherSpawnPositionPlanner.choose_position_from_chunk(
    selected_chunk.cx,
    selected_chunk.cy
  )

  local final_chunk = to_chunk_position(position)
  if not GeneratedChunkIndexGateway.has_chunk(dest_surface, final_chunk.x, final_chunk.y) then
    Logger.info({
      "[Export][Skip]",
      " reason=push_out_to_ungenerated_chunk",
      " dest_surface=", dest_surface.name,
      " name=", pick.name,
      " selected_chunk=", selected_chunk.key,
      " final_chunk={", final_chunk.x, ",", final_chunk.y, "}",
      " pos={", position.x, ",", position.y, "}",
    })
    return
  end

  local territory = TerritoryResolver.resolve(dest_surface, position)
  local territory_total, territory_fatal = count_territory_units(territory)

  if is_fatal_pick then
    if territory_fatal >= 1 then
      Logger.info({
        "[Export][Skip]",
        " reason=territory_fatal_cap",
        " dest_surface=", dest_surface.name,
        " name=", pick.name,
        " selected_chunk=", selected_chunk.key,
        " territory_fatal=", territory_fatal,
        " territory_fatal_cap=1",
      })
      return
    end
  else
    if territory_total >= 6 then
      Logger.info({
        "[Export][Skip]",
        " reason=territory_combat_cap",
        " dest_surface=", dest_surface.name,
        " name=", pick.name,
        " selected_chunk=", selected_chunk.key,
        " territory_total=", territory_total,
        " territory_combat_cap=6",
      })
      return
    end
  end

  local dest_evo = game.forces.enemy.get_evolution_factor(dest_surface)
  local quality = DemolisherQualityService.choose(dest_surface, {
    entity_name = pick.name,
    category = pick.category,
    dest_evo = dest_evo,
  })

  local result = DemolisherSpawnExecutor.spawn({
    surface = dest_surface,
    territory = territory,
    name = pick.name,
    position = position,
    quality = quality,
    force = "enemy",
  })

  if not result or not result.entity or not result.entity.valid then
    Logger.warn({
      "[Export][Fail]",
      " reason=spawn_failed",
      " trigger_surface=", source_surface_name,
      " dest_surface=", dest_surface.name,
      " name=", pick.name,
      " selected_chunk=", selected_chunk.key,
    })
    return
  end

  BossDemolisherFlagStore.mark_spawned(dest_surface.name, pick.name)
  ExportWindowStore.increment(source_surface_name)

  if ExportMessageStore.should_show() then
    Logger.debug(get_export_message())
    ExportMessageStore.mark_shown()
  end

  Logger.info({
    "[Export][Result]",
    " trigger_surface=", source_surface_name,
    " dest_surface=", dest_surface.name,
    " name=", pick.name,
    " category=", pick.category,
    " quality=", quality,
    " selected_chunk=", selected_chunk.key,
    " final_chunk={", final_chunk.x, ",", final_chunk.y, "}",
    " pos={", position.x, ",", position.y, "}",
  })
end

return M