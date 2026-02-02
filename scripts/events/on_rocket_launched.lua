-- scripts/events/on_rocket_launched.lua
local boss_demolisher_control = require("scripts.control.boss_demolisher_control")
local rocket_launch_history_store = require("__Manis_lib__/scripts/domain/demolisher/move/RocketLaunchHistoryStore")

local function handle(event)
  local silo = event.rocket_silo
  if not silo or not silo.valid then return end

  local surface = silo.surface
  if not surface or not surface.valid then return end

  rocket_launch_history_store.add(surface.name, silo.position, event.tick)

  local defeated =
    storage.manis_boss_demolisher_flag
    and storage.manis_boss_demolisher_flag[surface.name]
    and storage.manis_boss_demolisher_flag[surface.name].defeated == true

  if surface.name ~= "vulcanus" and not defeated then
    return
  end

  boss_demolisher_control.on_rocket_launched_export{
    trigger_surface = surface,
    silo = silo,
  }
end

script.on_event(defines.events.on_rocket_launched, handle)

return { handle = handle }