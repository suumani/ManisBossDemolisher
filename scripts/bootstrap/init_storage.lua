-- __ManisBossDemolisher__/scripts/bootstrap/init_storage.lua
-- ----------------------------
-- 責務:
-- - 本modが使用するstorage領域を初期化する。
-- - DeterministicRandom を初期化する。
-- ----------------------------

local M = {}

local DeterministicRandom = require("scripts.util.deterministic_random")

function M.initialize()
  storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}
  storage.manis_export_window_counter = storage.manis_export_window_counter or {}
  storage.manis_export_message_suppressed = storage.manis_export_message_suppressed or nil

  -- legacy残骸の削除
  storage.virtual_entities = nil
  storage.manis_surface_bounds = nil

  DeterministicRandom.init()
end

return M