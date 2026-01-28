-- __ManisBossDemolisher__/scripts/events/on_chunk_generated.lua
local bounds_tracker = require("scripts.services.surface_bounds_tracker")
local spawner = require("scripts.services.boss_demolisher_spawner")

script.on_event(defines.events.on_chunk_generated, function(event)
  bounds_tracker.on_chunk_generated(event)
    -- 仮想デモリッシャーの実体化処理
    spawner.process_virtual_queue(event)
end)