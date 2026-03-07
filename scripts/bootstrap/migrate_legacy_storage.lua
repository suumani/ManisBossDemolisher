-- __ManisBossDemolisher__/scripts/bootstrap/migrate_legacy_storage.lua
-- ----------------------------
-- 責務:
-- - defeated フラグの旧storageを新storageへ移行する。
-- - 移行後に旧キーを削除する。
-- ----------------------------

local M = {}

function M.migrate()
  local old = storage.manis_demolisher_killed_surface
  if type(old) ~= "table" then
    return
  end

  storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}

  for surface_name, value in pairs(old) do
    if value == true and type(surface_name) == "string" then
      storage.manis_boss_demolisher_flag[surface_name] =
        storage.manis_boss_demolisher_flag[surface_name] or {}

      storage.manis_boss_demolisher_flag[surface_name].defeated = true
    end
  end

  storage.manis_demolisher_killed_surface = nil
end

return M