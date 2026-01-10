-- __ManisBossDemolisher__/scripts/events/on_nth_tick_1min.lua
local Runner = require("scripts.services.BossDemolisherMovePlanRunner")

script.on_nth_tick(3600, function()
  Runner.run_one_step_if_present_all_surfaces()
end)