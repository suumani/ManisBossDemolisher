-- __ManisBossDemolisher__/scripts/services/boss_demolisher_spawner.lua
-- ----------------------------
-- 責務:
-- - デモリッシャーの生成位置を選定する。
-- - 生成位置の属するchunkからterritoryを解決する。
-- - territory未取得時は前提違反としてerror()する。
-- - segmented unitを物理生成する。
-- ----------------------------

local S = {}

local Categories = require("scripts.defines.demolisher_categories")
local DRand = require("scripts.util.DeterministicRandom")
local Logger = require("scripts.services.Logger")

local FORBIDDEN_HALF = 400
local PUSH_TO = 450
local MIN_SPAWN_RADIUS = 500

local function to_chunk_pos(pos)
  return {
    x = math.floor(pos.x / 32),
    y = math.floor(pos.y / 32),
  }
end

local function is_in_forbidden_rect(pos)
  return pos
    and pos.x >= -FORBIDDEN_HALF and pos.x <= FORBIDDEN_HALF
    and pos.y >= -FORBIDDEN_HALF and pos.y <= FORBIDDEN_HALF
end

local function push_out_of_forbidden(pos)
  if not is_in_forbidden_rect(pos) then
    return pos
  end

  if DRand.random(1, 2) == 1 then
    pos.x = (DRand.random(0, 1) == 0) and -PUSH_TO or PUSH_TO
  else
    pos.y = (DRand.random(0, 1) == 0) and -PUSH_TO or PUSH_TO
  end
  return pos
end

local function has_in_rect(surface, pos, half, predicate)
  local area = {
    { pos.x - half, pos.y - half },
    { pos.x + half, pos.y + half },
  }

  local entities = surface.find_entities_filtered({
    area = area,
    force = game.forces.enemy,
  })

  for _, entity in pairs(entities) do
    if entity.valid and predicate(entity) then
      return true
    end
  end

  return false
end

local function is_fatal(entity)
  return Categories.FATAL[entity.name] == true
end

local function is_combat(entity)
  return entity.name:find("demolisher", 1, true) and not Categories.FATAL[entity.name]
end

local function get_search_bounds_chunks(surface, force)
  local minx = math.huge
  local maxx = -math.huge
  local miny = math.huge
  local maxy = -math.huge
  local found = false

  for chunk in surface.get_chunks() do
    if force.is_chunk_charted(surface, { x = chunk.x, y = chunk.y }) then
      found = true
      if chunk.x < minx then minx = chunk.x end
      if chunk.x > maxx then maxx = chunk.x end
      if chunk.y < miny then miny = chunk.y end
      if chunk.y > maxy then maxy = chunk.y end
    end
  end

  local min_r_chunk = math.ceil(MIN_SPAWN_RADIUS / 32)

  if not found then
    return {
      minx = -min_r_chunk,
      maxx = min_r_chunk,
      miny = -min_r_chunk,
      maxy = min_r_chunk,
    }
  end

  if maxx < min_r_chunk then maxx = min_r_chunk end
  if minx > -min_r_chunk then minx = -min_r_chunk end
  if maxy < min_r_chunk then maxy = min_r_chunk end
  if miny > -min_r_chunk then miny = -min_r_chunk end

  return {
    minx = minx,
    maxx = maxx,
    miny = miny,
    maxy = maxy,
  }
end

local function resolve_force_name(force_value)
  local force_name = force_value
  if type(force_name) == "userdata" then
    force_name = force_name.name
  end
  if not force_name or force_name == "" then
    force_name = "enemy"
  end
  return force_name
end

local function resolve_quality_name(quality_value)
  local quality_name = quality_value
  if type(quality_name) == "userdata" then
    quality_name = quality_name.name
  end
  if not quality_name or quality_name == "" then
    quality_name = "normal"
  end
  return quality_name
end

local function resolve_territory(surface, position)
  local chunk_pos = to_chunk_pos(position)
  local territory = surface.get_territory_for_chunk(chunk_pos)

  if not territory then
    error(string.format(
      "MBD_TERRITORY_NOT_FOUND: surface=%s chunk={%d,%d} pos={%s,%s}",
      surface.name,
      chunk_pos.x,
      chunk_pos.y,
      tostring(position.x),
      tostring(position.y)
    ))
  end

  return territory
end

function S.choose_position(surface, opts)
  opts = opts or {}
  local category = opts.category or "combat"

  local force = game.forces.player
  local bounds = get_search_bounds_chunks(surface, force)

  local edge_minx = bounds.minx
  local edge_maxx = bounds.maxx
  local edge_miny = bounds.miny
  local edge_maxy = bounds.maxy

  local half = (category == "fatal") and 2000 or 0
  local predicate = (category == "fatal") and is_fatal or is_combat

  local function random_pos_in_chunk(cx, cy)
    local base_x = cx * 32
    local base_y = cy * 32
    return {
      x = base_x + DRand.random(0, 31),
      y = base_y + DRand.random(0, 31),
    }
  end

  local function choose_chunk_on_edge(side)
    if side == 1 then
      return edge_minx, DRand.random(edge_miny, edge_maxy)
    elseif side == 2 then
      return edge_maxx, DRand.random(edge_miny, edge_maxy)
    elseif side == 3 then
      return DRand.random(edge_minx, edge_maxx), edge_miny
    else
      return DRand.random(edge_minx, edge_maxx), edge_maxy
    end
  end

  local tries = (category == "fatal") and 30 or 15
  local pushed_count = 0
  local rejected_count = 0

  for _ = 1, tries do
    local side = DRand.random(1, 4)
    local cx, cy = choose_chunk_on_edge(side)
    local original_pos = random_pos_in_chunk(cx, cy)

    local pos = { x = original_pos.x, y = original_pos.y }
    if is_in_forbidden_rect(pos) then
      pushed_count = pushed_count + 1
      pos = push_out_of_forbidden(pos)
    end

    if category ~= "fatal" then
      return pos
    end

    if not has_in_rect(surface, pos, half, predicate) then
      return pos
    end

    rejected_count = rejected_count + 1
  end

  Logger.debug({
    "[ChoosePosition][Fail]",
    " surface=", surface.name,
    " category=", category,
    " tries=", tries,
    " bounds={", bounds.minx, ",", bounds.maxx, ",", bounds.miny, ",", bounds.maxy, "}",
    " half=", half,
    " pushed=", pushed_count,
    " rejected=", rejected_count,
  })

  return nil
end

function S.spawn(ctx)
  local surface = ctx and ctx.surface
  if not surface or not surface.valid then
    return nil
  end
  if not ctx.name or not ctx.position then
    return nil
  end

  local territory = resolve_territory(surface, ctx.position)
  local force_name = resolve_force_name(ctx.force or "enemy")
  local quality_name = resolve_quality_name(ctx.quality or "normal")

  local entity = surface.create_segmented_unit({
    name = ctx.name,
    position = ctx.position,
    force = force_name,
    quality = quality_name,
    territory = territory,
  })

  if entity and entity.valid then
    return {
      success = true,
      entity = entity,
    }
  end

  return nil
end

return S