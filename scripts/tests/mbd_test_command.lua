-- scripts/tests/mbd_test_command.lua
-- ------------------------------------------------------------
-- Responsibility:
--   Register a minimal test command for ManisBossDemolisher using Manis_TestFramework.
-- ------------------------------------------------------------

local TestRunner = require("__Manis_TestFramework__/scripts/test/TestRunner")
local CapCalc = require("__Manis_lib__/scripts/logic/DemolisherCapCalculator")

local function run_suite()
  local suite = {
    ["example: 1 + 1 = 2"] = function(T)
      T.assert_eq(1 + 1, 2, "math broken")
    end,
    ["example2 failed: 1 + 2 = 2"] = function(T)
      T.assert_eq(1 + 2, 2, "math broken")
    end,

    -- ------------------------------------------------------------
    -- Cap calculator tests
    -- base=40, step=0.05, max_reduction=0.75, floor=10
    -- ------------------------------------------------------------
    ["cap: level 0 returns base"] = function(T)
      local cap = CapCalc.calculate(40, 0, 0.05, 10, 0.75)
      T.assert_eq(cap, 40, "level=0 should not reduce cap")
    end,

    ["cap: level 1 reduces by 5% (40 -> 38)"] = function(T)
      local cap = CapCalc.calculate(40, 1, 0.05, 10, 0.75)
      T.assert_eq(cap, 38, "level=1 should reduce 5%")
    end,

    ["cap: level 2 reduces by 10% (40 -> 36)"] = function(T)
      local cap = CapCalc.calculate(40, 2, 0.05, 10, 0.75)
      T.assert_eq(cap, 36, "level=2 should reduce 10%")
    end,

    ["cap: level 15 hits max reduction 75% (40 -> 10)"] = function(T)
      local cap = CapCalc.calculate(40, 15, 0.05, 10, 0.75)
      T.assert_eq(cap, 10, "level=15 should be 75% reduction => floor 10")
    end,

    ["cap: level 999 still stays at floor (40 -> 10)"] = function(T)
      local cap = CapCalc.calculate(40, 999, 0.05, 10, 0.75)
      T.assert_eq(cap, 10, "cap must not go below floor")
    end,

    ["cap: breeding floor example (base 200, level 15 -> floor 50)"] = function(T)
      local cap = CapCalc.calculate(200, 15, 0.05, 50, 0.75)
      T.assert_eq(cap, 50, "breeding/fulgora floor should be 50 at max reduction")
    end,
  }

  TestRunner.run_suite("ManisBossDemolisher.sample", suite)
end

commands.add_command("mbd-test", "Run ManisBossDemolisher sample tests", function()
  run_suite()
end)