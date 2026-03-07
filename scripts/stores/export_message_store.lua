-- __ManisBossDemolisher__/scripts/stores/export_message_store.lua
-- ----------------------------
-- 責務:
-- - 輸出メッセージの30分抑止フラグを管理する。
-- ----------------------------

local M = {}

function M.should_show()
  return storage.manis_export_message_suppressed ~= true
end

function M.mark_shown()
  storage.manis_export_message_suppressed = true
end

function M.reset()
  storage.manis_export_message_suppressed = nil
end

return M