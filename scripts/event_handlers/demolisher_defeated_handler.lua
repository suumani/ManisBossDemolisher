-- __ManisBossDemolisher__/scripts/event_handlers/demolisher_defeated_handler.lua
-- ----------------------------
-- 責務:
-- - segmented unit の撃破を検知する。
-- - surface defeated フラグを初回のみ true にする。
-- ----------------------------

local M = {}

local Logger = require("scripts.logging.logger")
local BossDemolisherFlagStore = require("scripts.stores.boss_demolisher_flag_store")

function M.handle(event)
  local unit = event.segmented_unit
  if not unit or not unit.valid then
    return
  end

  local surface = unit.surface
  if not surface or not surface.valid then
    return
  end

  local changed = BossDemolisherFlagStore.mark_defeated(surface.name)
  if not changed then
    return
  end

  Logger.debug({
    "[Defeated]",
    " surface=", surface.name,
    " unit_number=", unit.unit_number,
    " prototype_name=", unit.prototype.name,
    " new_defeated_state=true",
  })
end

return M