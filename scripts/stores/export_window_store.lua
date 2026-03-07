-- __ManisBossDemolisher__/scripts/stores/export_window_store.lua
-- ----------------------------
-- 責務:
-- - 輸出元 surface ごとの30分ウィンドウ内輸出件数を管理する。
-- - 成功spawn時のみ加算する。
-- ----------------------------

local M = {}

local function ensure()
  storage.manis_export_window_counter = storage.manis_export_window_counter or {}
  return storage.manis_export_window_counter
end

function M.get_count(surface_name)
  local counters = ensure()
  return counters[surface_name] or 0
end

function M.can_export(surface_name, limit)
  return M.get_count(surface_name) < limit
end

function M.increment(surface_name)
  local counters = ensure()
  counters[surface_name] = (counters[surface_name] or 0) + 1
end

function M.reset_all()
  storage.manis_export_window_counter = {}
end

return M