-- __ManisBossDemolisher__/scripts/event_handlers/demolisher_defeated_handler.lua
-- ----------------------------
-- 責務:
-- - physical 実体の撃破を検知する。
-- - surface defeated フラグを初回のみ true にする。
-- ----------------------------

local M = {}

local DemolisherNames = require("__Manis_definitions__/scripts/definition/DemolisherNames")
local Logger = require("scripts.logging.logger")
local BossDemolisherFlagStore = require("scripts.stores.boss_demolisher_flag_store")

local ALL_SET = {}
for _, name in ipairs(DemolisherNames.ALL) do
  ALL_SET[name] = true
end

function M.handle(event)
  local entity = event.entity
  if not entity or not entity.valid then
    return
  end

  if ALL_SET[entity.name] ~= true then
    return
  end

  local surface = entity.surface
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
    " entity_name=", entity.name,
    " new_defeated_state=true",
  })
end

return M