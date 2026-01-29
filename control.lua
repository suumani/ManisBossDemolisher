-- __ManisBossDemolisher__/control.lua
require("scripts.events.on_chunk_generated")
require("scripts.events.on_entity_died")
require("scripts.events.on_nth_tick_1min")
require("scripts.events.on_nth_tick_30min")
require("scripts.events.on_rocket_launched")

-- test
require("scripts.tests.mbd_test_command")

local function init()
  storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}
  if not storage.virtual_entities then
    storage.virtual_entities = {}
  end
end

script.on_init(init)
script.on_configuration_changed(init)

