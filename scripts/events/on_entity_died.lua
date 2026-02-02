-- __ManisBossDemolisher__/scripts/events/on_entity_died.lua
-- ----------------------------
-- Responsibility:
--   Defeated flag update (physical only).
--   - Scope: DemolisherNames.ALL
--   - Store: storage.manis_boss_demolisher_flag[surface].defeated = true
--   - Log only on first transition (OBS-DEF-001)
-- ----------------------------

local DemolisherNames = require("__Manis_definitions__/scripts/definition/DemolisherNames")
local Logger = require("scripts.services.Logger")

-- Build set once (load time)
local ALL_SET = {}
for _, n in ipairs(DemolisherNames.ALL) do
  ALL_SET[n] = true
end

script.on_event(defines.events.on_entity_died, function(event)
  local entity = event.entity
  if not entity then return end

  local name = entity.name
  if not name or ALL_SET[name] ~= true then
    return
  end

  local surface = entity.surface
  if not surface or not surface.valid then return end

  storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}
  local per_surface = storage.manis_boss_demolisher_flag[surface.name]
  if not per_surface then
    per_surface = {}
    storage.manis_boss_demolisher_flag[surface.name] = per_surface
  end

  if per_surface.defeated == true then
    return
  end

  per_surface.defeated = true

  -- OBS-DEF-001 (once)
  Logger.debug({
    "",
    "[Defeated] surface=", surface.name,
    " entity_name=", name,
    " new_defeated_state=true"
  })
end)