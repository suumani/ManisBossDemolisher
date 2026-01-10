-- ----------------------------
-- 抽選 scripts/services/boss_demolisher_selector.lua
-- ----------------------------
local selector = {}

local DemolisherNames = require("__Manis_definitions__/scripts/definition/DemolisherNames") 
local DRand = require("scripts.util.DeterministicRandom")

local function strip_alt_suffix(name)
  return (name:gsub("%-alt$", ""))
end

-- storage.manis_boss_demolisher_flag[surface.name][entity_name] = true を前提
local function has_spawned(surface, entity_name)
  local entity_base_name = strip_alt_suffix(entity_name)
  local flags = storage.manis_boss_demolisher_flag
  if not flags then return false end
  local per_surface = flags[surface.name]
  if not per_surface then return false end
  return per_surface[entity_base_name] == true
end

local Categories = require("scripts.defines.demolisher_categories")

-- ----------------------------
-- デモリッシャーの選択（段階解放）
-- ボスの出現ルール 
-- 1匹目の出現：small-demolisher、medium-demolisher、big-demolisher、manis-behemoth-demolisherから抽選される 
-- そのsurfaceでmanis-behemoth-demolisher出現済みであれば、抽選にmanis-speedstar-small-demolisherとmanis-gigantic-small-demolisherを抽選対象に追加 
-- そのsurfaceでmanis-speedstar-small-demolisher出現済みであれば、抽選にmanis-speedstar-medium-demolisherを抽選対象に追加 
-- そのsurfaceでmanis-speedstar-medium-demolisher出現済みであれば、抽選にmanis-speedstar-big-demolisherを抽選対象に追加 
-- そのsurfaceでmanis-speedstar-big-demolisher出現済みであれば、抽選にmanis-speedstar-behemoth-demolisherを抽選対象に追加 
-- そのsurfaceでmanis-gigantic-small-demolisher出現済みであれば、抽選にmanis-gigantic-medium-demolisherを抽選対象に追加 
-- そのsurfaceでmanis-gigantic-medium-demolisher出現済みであれば、抽選にmanis-gigantic-big-demolisherを抽選対象に追加 
-- そのsurfaceでmanis-gigantic-big-demolisher出現済みであれば、抽選にmanis-gigantic-behemoth-demolisherを抽選対象に追加 
-- そのsurfaceでmanis-speedstar-behemoth-demolisherとmanis-gigantic-behemoth-demolisher出現済みであれば、manis-crazy-gigantic-king-demolisherを抽選対象に追加 
-- ----------------------------
function selector.choose_demolisher(surface, ctx)
	local pool = {
		DemolisherNames.MANIS_SMALL,
		DemolisherNames.MANIS_MEDIUM,
		DemolisherNames.MANIS_BIG,
		DemolisherNames.MANIS_BEHEMOTH,
	}

	-- behemoth到達で分岐開始
	if has_spawned(surface, DemolisherNames.MANIS_BEHEMOTH) then
		table.insert(pool, DemolisherNames.MANIS_SPEEDSTAR_SMALL)
		table.insert(pool, DemolisherNames.MANIS_GIGANTIC_SMALL)
	end

	-- speedstar系列
	if has_spawned(surface, DemolisherNames.MANIS_SPEEDSTAR_SMALL) then
		table.insert(pool, DemolisherNames.MANIS_SPEEDSTAR_MEDIUM)
	end
	if has_spawned(surface, DemolisherNames.MANIS_SPEEDSTAR_MEDIUM) then
		table.insert(pool, DemolisherNames.MANIS_SPEEDSTAR_BIG)
	end
	if has_spawned(surface, DemolisherNames.MANIS_SPEEDSTAR_BIG) then
		table.insert(pool, DemolisherNames.MANIS_SPEEDSTAR_BEHEMOTH)
	end

	-- gigantic系列
	if has_spawned(surface, DemolisherNames.MANIS_GIGANTIC_SMALL) then
		table.insert(pool, DemolisherNames.MANIS_GIGANTIC_MEDIUM)
	end
	if has_spawned(surface, DemolisherNames.MANIS_GIGANTIC_MEDIUM) then
		table.insert(pool, DemolisherNames.MANIS_GIGANTIC_BIG)
	end
	if has_spawned(surface, DemolisherNames.MANIS_GIGANTIC_BIG) then
		table.insert(pool, DemolisherNames.MANIS_GIGANTIC_BEHEMOTH)
	end

	-- 最終：両系統behemoth到達でkingを追加
	if has_spawned(surface, DemolisherNames.MANIS_SPEEDSTAR_BEHEMOTH)
		and has_spawned(surface, DemolisherNames.MANIS_GIGANTIC_BEHEMOTH)
	then
		table.insert(pool, DemolisherNames.MANIS_CRAZY_KING)
	end

    -- 抽選（均等）
	local idx = DRand.random(1, #pool)
	local name = pool[idx]
	local cat = Categories.FATAL[name] and "fatal" or "combat"
	if surface.name ~= "vulcanus" then name = name.."-alt" end
	return { name = name, category = cat }
end

-- ----------------------------
-- 輸出先surfaceの選択
-- ・存在するsurfaceのみ
-- ・輸出元（trigger_surface）は除外
-- ----------------------------
function selector.choose_destination_surface(ctx)
  local trigger = ctx and ctx.trigger_surface
  local trigger_name = (trigger and trigger.valid) and trigger.name or nil

  local candidates = {}

  local function add(name)
    if name ~= trigger_name then
      local s = game.surfaces[name]
      if s then
        table.insert(candidates, s)
      end
    end
  end

  add("nauvis")
  add("vulcanus")
  add("gleba")
  add("fulgora")
  add("aquilo")

  if #candidates == 0 then
    return nil
  end

  return candidates[DRand.random(1, #candidates)]
end

-- ----------------------------
-- surface選択（未発見/存在なしは除外）
-- 惑星選択の段階で20%であることに留意
-- ----------------------------
function selector.choose_surface(ctx)
  local names = { "nauvis", "vulcanus", "gleba", "fulgora", "aquilo" }

  local name = names[DRand.random(1, #names)]
  local surface = game.surfaces[name]

  -- もし存在しない（mod構成や将来変更など）場合は安全に終了
  if not surface then return nil end
  return surface
end

return selector