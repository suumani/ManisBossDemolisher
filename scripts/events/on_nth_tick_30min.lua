-- __ManisBossDemolisher__/scripts/events/on_nth_tick_30min.lua
-- ----------------------------
-- デモリッシャー輸出メッセージフラグを下す
-- ----------------------------

local TICKS_30_MIN = 60 * 60 * 30

script.on_nth_tick(TICKS_30_MIN, function()
  storage.manis_export_message_suppressed = nil
end)