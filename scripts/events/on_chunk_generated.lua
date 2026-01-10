-- scripts/events/on_chunk_generated.lua
local bounds_tracker = require("scripts.services.surface_bounds_tracker")

script.on_event(defines.events.on_chunk_generated, function(event)
  bounds_tracker.on_chunk_generated(event)
end)