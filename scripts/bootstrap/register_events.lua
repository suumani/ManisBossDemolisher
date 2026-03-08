-- __ManisBossDemolisher__/scripts/bootstrap/register_events.lua
-- ----------------------------
-- 責務:
-- - ManisBossDemolisher のイベント登録を一元管理する。
-- ----------------------------

local M = {}

local DemolisherDefeatedHandler = require("scripts.event_handlers.demolisher_defeated_handler")
local ExportWindowResetHandler = require("scripts.event_handlers.export_window_reset_handler")
local RocketLaunchExportHandler = require("scripts.event_handlers.rocket_launch_export_handler")

function M.register()
  script.on_event(defines.events.on_segmented_unit_died, DemolisherDefeatedHandler.handle)
  script.on_event(defines.events.on_rocket_launched, RocketLaunchExportHandler.handle)
  script.on_nth_tick(60 * 60 * 30, ExportWindowResetHandler.handle)
end

return M