-- __ManisBossDemolisher__/scripts/control.lua
require("scripts.events.on_chunk_generated")
require("scripts.events.on_entity_died")
require("scripts.events.on_nth_tick_1min")
require("scripts.events.on_nth_tick_30min")
require("scripts.events.on_rocket_launched")

local function init()
    storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}
end

script.on_init(init)
script.on_configuration_changed(init)
