-- __ManisBossDemolisher__/scripts/event_handlers/export_window_reset_handler.lua
-- ----------------------------
-- 責務:
-- - 30分ウィンドウの輸出元カウントをリセットする。
-- - 輸出メッセージ抑止フラグをリセットする。
-- ----------------------------

local M = {}

local ExportWindowStore = require("scripts.stores.export_window_store")
local ExportMessageStore = require("scripts.stores.export_message_store")

function M.handle()
  ExportWindowStore.reset_all()
  ExportMessageStore.reset()
end

return M