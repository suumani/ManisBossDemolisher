-- ----------------------------
-- Spawn / Positioning
-- scripts/services/boss_demolisher_spawner.lua
-- ----------------------------
local S = {}

local Categories = require("scripts.defines.demolisher_categories")
local DRand = require("scripts.util.DeterministicRandom")

local function has_in_rect(surface, pos, half, predicate)
  local area = {
    { pos.x - half, pos.y - half },
    { pos.x + half, pos.y + half }
  }
  local ents = surface.find_entities_filtered{ area = area, force = game.forces.enemy }
  for _, e in pairs(ents) do
    if e.valid and predicate(e) then
      return true
    end
  end
  return false
end

local function is_fatal(e)
  return Categories.FATAL[e.name] == true
end

local function is_combat(e)
  -- demolisher かつ fatal でない、を combat とみなす（最小実装）
  return e.name:find("demolisher", 1, true) and not Categories.FATAL[e.name]
end

local function get_charted_aabb_chunks(surface, force) 
	local minx, maxx = math.huge, -math.huge 
	local miny, maxy = math.huge, -math.huge 
	local found = false 
	for c in surface.get_chunks() do 
		if force.is_chunk_charted(surface, { x = c.x, y = c.y }) then 
			found = true 
			if c.x < minx then 
				minx = c.x 
			end if c.x > maxx then 
				maxx = c.x 
			end if c.y < miny then 
				miny = c.y 
			end if c.y > maxy then 
				maxy = c.y 
			end 
		end 
	end if not found then 
		return nil 
	end return { minx = minx, maxx = maxx, miny = miny, maxy = maxy } 
end

-- ----------------------------
-- Position selection
-- opts.category = "fatal"|"combat"
-- opts.name     = entity name (任意：将来king特例に使える)
-- ----------------------------
function S.choose_position(surface, opts)
  opts = opts or {}
  local category = opts.category or "combat"

  local force = game.forces.player
  local aabb = get_charted_aabb_chunks(surface, force)
  if not aabb then
    return { x = 0, y = 0 }
  end

  -- margin: charted外周から何チャンク外に出すか
  -- （Combatは近め、Fatalは遠め）
  local margin = (category == "fatal") and 6 or 1

  -- 密度cap（矩形半径）
  local half = (category == "fatal") and 2000 or 500
  local predicate = (category == "fatal") and is_fatal or is_combat

  local function tile_center_of_chunk(cx, cy)
    return { x = cx * 32 + 16, y = cy * 32 + 16 }
  end

  local function choose_chunk_on_side(side)
    -- side: 1 left, 2 right, 3 top, 4 bottom
    if side == 1 then
      return (aabb.minx - margin), DRand.random(aabb.miny, aabb.maxy)
    elseif side == 2 then
      return (aabb.maxx + margin), DRand.random(aabb.miny, aabb.maxy)
    elseif side == 3 then
      return DRand.random(aabb.minx, aabb.maxx), (aabb.miny - margin)
    else
      return DRand.random(aabb.minx, aabb.maxx), (aabb.maxy + margin)
    end
  end

  -- リトライ回数：密度capで弾かれることがあるので複数回試す
  local tries = (category == "fatal") and 30 or 15

  for _ = 1, tries do
    local side = DRand.random(1, 4)
    local cx, cy = choose_chunk_on_side(side)
    local pos = tile_center_of_chunk(cx, cy)

    -- 密度capチェック
    if not has_in_rect(surface, pos, half, predicate) then
      return pos
    end
  end

  -- 最後のフォールバック：密度capを無視してでも返すと事故るので nil
  return nil
end

local function choose_cardinal_direction(from_pos, to_pos)
  local dx = to_pos.x - from_pos.x
  local dy = to_pos.y - from_pos.y

  if math.abs(dx) >= math.abs(dy) then
    return (dx >= 0) and defines.direction.east or defines.direction.west
  else
    return (dy >= 0) and defines.direction.south or defines.direction.north
  end
end

-- ----------------------------
-- Spawn wrapper
-- ctx: {surface,name,position,quality,category}
-- ----------------------------
function S.spawn(ctx)
	local surface = ctx and ctx.surface
	if not surface or not surface.valid then return nil end
	if not ctx.name or not ctx.position then return nil end

	local dir = nil
	if ctx.town_center then
		dir = choose_cardinal_direction(ctx.position, ctx.town_center)
	end

	local ent = surface.create_entity{
		name     = ctx.name,
		position = ctx.position,
		force    = game.forces.enemy,
		quality  = ctx.quality,
		direction = dir, -- nilなら省略扱い
	}

	return ent
end

return S