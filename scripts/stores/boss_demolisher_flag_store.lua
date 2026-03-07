-- __ManisBossDemolisher__/scripts/stores/boss_demolisher_flag_store.lua
-- ----------------------------
-- 責務:
-- - defeated / spawned フラグを storage 上で管理する。
-- ----------------------------

local M = {}

local function ensure_surface(surface_name)
  storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}
  storage.manis_boss_demolisher_flag[surface_name] =
    storage.manis_boss_demolisher_flag[surface_name] or {}

  return storage.manis_boss_demolisher_flag[surface_name]
end

function M.is_defeated(surface_name)
  local per_surface = storage.manis_boss_demolisher_flag
    and storage.manis_boss_demolisher_flag[surface_name]

  return per_surface and per_surface.defeated == true or false
end

function M.mark_defeated(surface_name)
  local per_surface = ensure_surface(surface_name)
  if per_surface.defeated == true then
    return false
  end

  per_surface.defeated = true
  return true
end

function M.has_spawned(surface_name, entity_name)
  local per_surface = storage.manis_boss_demolisher_flag
    and storage.manis_boss_demolisher_flag[surface_name]

  return per_surface and per_surface[entity_name] == true or false
end

function M.mark_spawned(surface_name, entity_name)
  local per_surface = ensure_surface(surface_name)
  per_surface[entity_name] = true
end

return M