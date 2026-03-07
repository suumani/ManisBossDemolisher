-- __ManisBossDemolisher__/scripts/services/demolisher_species_selector.lua
-- ----------------------------
-- 責務:
-- - 輸出対象デモリッシャー種を段階解放ルールで選定する。
-- - surface に応じて alt / non-alt 名へ正規化する。
-- ----------------------------

local M = {}

local DemolisherNames = require("__Manis_definitions__/scripts/definition/DemolisherNames")
local Categories = require("scripts.defines.demolisher_categories")
local DeterministicRandom = require("scripts.util.deterministic_random")
local BossDemolisherFlagStore = require("scripts.stores.boss_demolisher_flag_store")

local function name_for_surface(surface, name)
  if not name or type(name) ~= "string" then
    return name
  end

  local is_alt = (name:sub(-4) == "-alt")

  if surface and surface.valid and surface.name ~= "vulcanus" then
    return is_alt and name or (name .. "-alt")
  end

  return is_alt and name:sub(1, -5) or name
end

local function category_key(name)
  if type(name) ~= "string" then
    return name
  end

  if name:sub(-4) == "-alt" then
    return name:sub(1, -5)
  end

  return name
end

local function has_spawned(surface, base_name)
  local normalized_name = name_for_surface(surface, base_name)
  return BossDemolisherFlagStore.has_spawned(surface.name, normalized_name)
end

local function build_pool(surface)
  local pool = {
    DemolisherNames.MANIS_SMALL,
    DemolisherNames.MANIS_MEDIUM,
    DemolisherNames.MANIS_BIG,
    DemolisherNames.MANIS_BEHEMOTH,
  }

  if has_spawned(surface, DemolisherNames.MANIS_BEHEMOTH) then
    table.insert(pool, DemolisherNames.MANIS_SPEEDSTAR_SMALL)
    table.insert(pool, DemolisherNames.MANIS_GIGANTIC_SMALL)
  end

  if has_spawned(surface, DemolisherNames.MANIS_SPEEDSTAR_SMALL) then
    table.insert(pool, DemolisherNames.MANIS_SPEEDSTAR_MEDIUM)
  end
  if has_spawned(surface, DemolisherNames.MANIS_SPEEDSTAR_MEDIUM) then
    table.insert(pool, DemolisherNames.MANIS_SPEEDSTAR_BIG)
  end
  if has_spawned(surface, DemolisherNames.MANIS_SPEEDSTAR_BIG) then
    table.insert(pool, DemolisherNames.MANIS_SPEEDSTAR_BEHEMOTH)
  end

  if has_spawned(surface, DemolisherNames.MANIS_GIGANTIC_SMALL) then
    table.insert(pool, DemolisherNames.MANIS_GIGANTIC_MEDIUM)
  end
  if has_spawned(surface, DemolisherNames.MANIS_GIGANTIC_MEDIUM) then
    table.insert(pool, DemolisherNames.MANIS_GIGANTIC_BIG)
  end
  if has_spawned(surface, DemolisherNames.MANIS_GIGANTIC_BIG) then
    table.insert(pool, DemolisherNames.MANIS_GIGANTIC_BEHEMOTH)
  end

  if has_spawned(surface, DemolisherNames.MANIS_SPEEDSTAR_BEHEMOTH)
    and has_spawned(surface, DemolisherNames.MANIS_GIGANTIC_BEHEMOTH)
  then
    table.insert(pool, DemolisherNames.MANIS_CRAZY_KING_SMALL)
  end

  return pool
end

function M.choose_demolisher(surface)
  if not surface or not surface.valid then
    return nil
  end

  local pool = build_pool(surface)
  if #pool == 0 then
    return nil
  end

  local picked_base_name = pool[DeterministicRandom.random(1, #pool)]
  local picked_name = name_for_surface(surface, picked_base_name)
  local picked_category = Categories.FATAL[category_key(picked_name)] and "fatal" or "combat"

  return {
    name = picked_name,
    category = picked_category,
  }
end

return M