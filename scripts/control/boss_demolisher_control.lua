-- __ManisBossDemolisher__/scripts/control/boss_demolisher_control.lua
-- ----------------------------
-- 責務:
-- - ロケット発射による輸出トリガを処理する。
-- - 30分に1回まで輸出メッセージを表示する。
-- - 輸出先surfaceと輸出対象デモリッシャーを決定する。
-- - physical実体のみを対象にcap判定を行う。
-- - 位置と品質を確定し、Spawnerへ生成を委譲する。
-- - 出現済みフラグ(manis_boss_demolisher_flag)を更新する。
-- ----------------------------

local boss_demolisher_control = {}

local selector = require("scripts.services.boss_demolisher_selector")
local spawner = require("scripts.services.boss_demolisher_spawner")
local probability = require("scripts.services.boss_demolisher_probability")
local quality = require("scripts.services.quality_assigner")
local Logger = require("scripts.services.Logger")
local CapManager = require("scripts.services.boss_demolisher_cap_manager")
local TestHooks = require("scripts.tests.infrastructure.TestHooks")
local DemolisherQuery = require("__Manis_lib__/scripts/queries/DemolisherQuery")
local Categories = require("scripts.defines.demolisher_categories")

local function get_dest_evo(dest_surface)
  local ov = TestHooks.try_get_export_evo_override(dest_surface.name)
  if type(ov) == "number" then
    return ov
  end
  return game.forces.enemy.get_evolution_factor(dest_surface)
end

local function count_total_demolishers(surface)
  local visible_ents = DemolisherQuery.find_demolishers(surface) or {}
  local nonfatal_count = 0
  local fatal_count = 0

  for _, entity in pairs(visible_ents) do
    if entity.valid then
      if Categories.FATAL[entity.name] then
        fatal_count = fatal_count + 1
      else
        nonfatal_count = nonfatal_count + 1
      end
    end
  end

  return nonfatal_count, fatal_count
end

function boss_demolisher_control.on_rocket_launched_export(ctx)
  local trigger_surface = ctx and ctx.trigger_surface
  if not trigger_surface or not trigger_surface.valid then
    return
  end

  if not storage.manis_export_message_suppressed then
    Logger.debug({ "mani-boss-demolisher-message.boss-demolisher-exported" })
    storage.manis_export_message_suppressed = true
  end

  if not probability.should_spawn(trigger_surface, ctx, "export") then
    return
  end

  local dest_surface = selector.choose_destination_surface(ctx)
  if not dest_surface then
    return
  end

  local pick = selector.choose_demolisher(dest_surface, ctx)
  if not pick then
    return
  end

  local force = game.forces.player
  local combat_cap = CapManager.get_combat_cap(force)
  local fatal_cap = CapManager.get_fatal_cap(force)

  local cap_ov = TestHooks.try_get_export_cap_override()
  if cap_ov then
    if type(cap_ov.global) == "number" then
      combat_cap = cap_ov.global
    end
    if type(cap_ov.fatal) == "number" then
      fatal_cap = cap_ov.fatal
    end
  end

  local cur_nonfatal, cur_fatal = count_total_demolishers(dest_surface)
  local cur_total = cur_nonfatal + cur_fatal
  local is_fatal_pick = (pick.category == "fatal") or Categories.FATAL[pick.name]

  if is_fatal_pick then
    if cur_fatal >= fatal_cap then
      Logger.info(string.format(
        "[Skip] Fatal Cap Reached on %s. Fatal:%d >= Cap:%d (Total:%d Combat:%d)",
        dest_surface.name,
        cur_fatal,
        fatal_cap,
        cur_total,
        cur_nonfatal
      ))
      return
    end
  else
    if cur_total >= combat_cap then
      Logger.info(string.format(
        "[Skip] Combat Cap Reached on %s. Total:%d >= Cap:%d (Combat:%d Fatal:%d FatalCap:%d)",
        dest_surface.name,
        cur_total,
        combat_cap,
        cur_nonfatal,
        cur_fatal,
        fatal_cap
      ))
      return
    end
  end

  local position = nil

  local pos_ov = TestHooks.try_get_export_spawn_position()
  if pos_ov and pos_ov.surface_name == dest_surface.name then
    position = { x = pos_ov.x, y = pos_ov.y }
  else
    position = spawner.choose_position(dest_surface, {
      category = pick.category,
      name = pick.name,
    })
  end

  if not position then
    Logger.info({
      "[Export][Skip]",
      " reason=no_valid_position",
      " dest=", dest_surface.name,
      " category=", pick.category or "unknown",
      " name=", pick.name or "unknown",
    })
    return
  end

  local dest_evo = 0
  if dest_surface.valid then
    dest_evo = get_dest_evo(dest_surface)
  end

  local q = quality.choose(dest_surface, {
    entity_name = pick.name,
    category = pick.category,
    dest_evo = dest_evo,
  })

  local result = spawner.spawn({
    surface = dest_surface,
    name = pick.name,
    position = position,
    quality = q,
    category = pick.category,
  })

  if result and result.entity and result.entity.valid then
    Logger.info({
      "[Export][Result]",
      " dest=", dest_surface.name,
      " kind=phy",
      " name=", pick.name,
      " pos={", position.x, ",", position.y, "}",
    })

    local entity_base_name = pick.name
    storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}
    storage.manis_boss_demolisher_flag[dest_surface.name] =
      storage.manis_boss_demolisher_flag[dest_surface.name] or {}
    storage.manis_boss_demolisher_flag[dest_surface.name][entity_base_name] = true
  else
    Logger.debug("[Fail] Spawn failed (Internal error).")
  end
end

return boss_demolisher_control