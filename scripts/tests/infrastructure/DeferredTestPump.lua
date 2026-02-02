-- __ManisBossDemolisher__/scripts/tests/infrastructure/DeferredTestPump.lua
-- ------------------------------------------------------------
-- Responsibility:
--   The ONLY tick pump for deferred tests in THIS mod.
-- Notes:
--   - Do not register per-test nth_tick.
-- ------------------------------------------------------------
local Deferred = require("scripts.tests.infrastructure.DeferredTestRunner")
local TestRuntime = require("scripts.tests.infrastructure.TestRuntime")
local i = 0
script.on_nth_tick(1, function()
  game.print("1 tick test available! Test Mode Now! (" .. i .. ")")
  i = i + 1
  if not TestRuntime.is_enabled() then return end
  Deferred._pump()
end)

return {}