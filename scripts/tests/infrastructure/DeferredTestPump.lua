-- __ManisBossDemolisher__/scripts/tests/infrastructure/DeferredTestPump.lua
-- ------------------------------------------------------------
-- Responsibility:
--   The ONLY tick pump for deferred tests in THIS mod.
-- Notes:
--   - Do not register per-test nth_tick.
-- ------------------------------------------------------------
local Deferred = require("scripts.tests.infrastructure.DeferredTestRunner")
local i = 0
script.on_nth_tick(1, function()
  Deferred._pump()
  game.print("1 tick test available (" .. i .. ")")
  i = i + 1
end)

return {}