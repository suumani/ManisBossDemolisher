-- __ManisBossDemolisher__/scripts/events/on_rocket_launched.lua

local boss_demolisher_control = require("scripts.control.boss_demolisher_control")
local util = require("scripts.common.util")
local rocket_launch_history_store = require("__Manis_lib__/scripts/domain/demolisher/move/RocketLaunchHistoryStore")

script.on_event(defines.events.on_rocket_launched, function(event)
  local silo = event.rocket_silo
  if not silo or not silo.valid then
    return
  end

  local surface = silo.surface
  if not surface or not surface.valid then
    return
  end

  rocket_launch_history_store.add(surface.name, silo.position, event.tick)

  local killed = storage.manis_demolisher_killed_surface
    and storage.manis_demolisher_killed_surface[surface.name] == true

  if surface.name ~= "vulcanus" and not killed then
    return
  end

  boss_demolisher_control.on_rocket_launched_export{
    trigger_surface = surface,
    silo = silo,
  }
end)