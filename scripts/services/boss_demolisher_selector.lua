-- __ManisBossDemolisher__/scripts/services/boss_demolisher_selector.lua
-- ----------------------------
-- 抽選
-- ----------------------------
local selector = {}

local DemolisherNames = require("__Manis_definitions__/scripts/definition/DemolisherNames")
local DRand = require("scripts.util.DeterministicRandom")
local TestHooks = require("scripts.tests.infrastructure.TestHooks")
local Categories = require("scripts.defines.demolisher_categories")

-- Return species name for the given surface policy.
-- - vulcanus: non-alt
-- - others : alt
local function name_for_surface(surface, name)
  if not name or type(name) ~= "string" then return name end
  local is_alt = (name:sub(-4) == "-alt")

  if surface and surface.valid and surface.name ~= "vulcanus" then
    return is_alt and name or (name .. "-alt")
  else
    -- vulcanus (or unknown surface): non-alt
    return is_alt and name:sub(1, -5) or name
  end
end

-- Category table is assumed to be keyed by non-alt names.
local function category_key(name)
  if type(name) ~= "string" then return name end
  if name:sub(-4) == "-alt" then
    return name:sub(1, -5)
  end
  return name
end

-- storage.manis_boss_demolisher_flag[surface.name][name] = true を前提
local function has_spawned(surface, base_name)
  local flags = storage.manis_boss_demolisher_flag
  if not flags then return false end
  local per_surface = flags[surface.name]
  if not per_surface then return false end

  local name = name_for_surface(surface, base_name)
  return per_surface[name] == true
end

local function build_pool(surface)
  -- Pool is expressed in non-alt names; surface policy is applied when checking flags and when returning a pick.
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

  return pool
end

-- ----------------------------
-- デモリッシャーの選択（段階解放）
-- ----------------------------
function selector.choose_demolisher(surface, ctx)
  -- Test hook: force pick (pack/scenario driven)
  local forced = TestHooks.try_get_export_force_pick()
  if forced and forced.name then
    local picked = name_for_surface(surface, forced.name)
    local key = category_key(picked)
    local cat = forced.category or (Categories.FATAL[key] and "fatal" or "combat")
    return { name = picked, category = cat }
  end

  local pool = build_pool(surface)

  -- 抽選（均等）
  local idx = DRand.random(1, #pool)
  local picked_base = pool[idx]

  local picked = name_for_surface(surface, picked_base)
  local key = category_key(picked)
  local cat = Categories.FATAL[key] and "fatal" or "combat"

  return { name = picked, category = cat }
end

-- ----------------------------
-- 輸出先surfaceの選択
-- ・存在するsurfaceのみ
-- ・輸出元（trigger_surface）は除外
-- ----------------------------
function selector.choose_destination_surface(ctx)
  -- Test hook: force destination surface name (pack/scenario driven)
  local forced_name = TestHooks.try_get_export_dest_surface_name()
  if forced_name then
    return game.surfaces[forced_name]
  end

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

-- Test-only: return current candidate pool.
-- This does not include randomness; used by progression tests.
function selector._debug_build_pool(surface)
  if not surface or not surface.valid then return {} end
  return build_pool(surface)
end

return selector