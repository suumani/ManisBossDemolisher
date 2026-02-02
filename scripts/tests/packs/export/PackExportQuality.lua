-- scripts/tests/packs/export/PackExportQuality.lua
-- ------------------------------------------------------------
-- Responsibility:
--   PACK-EXPORT-QUAL:
--   World-state regression tests for Export quality rules.
--   Primary oracle is world state (entity/virtual + quality).
--
-- Covered specs:
--   - EXP-QUAL-001: first-of-type is always normal
--   - EXP-EVO-001: evo reference is dest_surface (trigger is bug)
--
-- Notes:
--   - Deterministic: uses export_dest_surface_name + roll override + evo overrides.
--   - Avoids "N trials" distribution tests; one-shot proof via controlled roll.
--   - 初回normal判定のキーは entity_name（完全一致）である
-- ------------------------------------------------------------
-- Test Results:
-- ver.0.1.6 Pass 1 Fail 1
-- ------------------------------------------------------------
local TestRunner = require("__Manis_TestFramework__/scripts/test/TestRunner")

local Bootstrap = require("scripts.tests.infrastructure.TestBootstrap")
local Oracle    = require("scripts.tests.infrastructure.WorldOracle")
local Config    = require("scripts.tests.infrastructure.TestConfig")

local RocketEvent = require("scripts.events.on_rocket_launched")

local PLANETS = { "nauvis", "gleba", "fulgora", "vulcanus", "aquilo" }

-- ------------------------------------------------------------
-- helpers
-- ------------------------------------------------------------
local function ensure_surface(name)
  local s = game.surfaces[name]
  if s then return s end
  return game.create_surface(name, {})
end

local function ensure_all_surfaces()
  for _, n in ipairs(PLANETS) do
    ensure_surface(n)
  end
end

local function fire_rocket(surface)
  RocketEvent.handle({
    rocket_silo = {
      valid = true,
      surface = surface,
      position = { x = 0, y = 0 },
    },
    tick = game.tick,
  })
end

local function assert_added_one_with_quality(T, dest_surface_name, before_detail, after_detail, expected_quality, msg)
  local added = Oracle.find_newly_added_one(dest_surface_name, before_detail, after_detail)
  T.assert(added ~= nil, msg .. " (no added entity found)")
  T.assert(added.kind ~= "error",
    msg .. " (expected exactly one add, but added_count=" .. tostring(added.added_count) .. ")")

  T.assert(added.quality == expected_quality,
    msg .. " (expected quality=" .. tostring(expected_quality) .. " but got " .. tostring(added.quality) .. ")")
end

-- ------------------------------------------------------------
local function run_suite()
  local suite = {}

  -- ----------------------------------------------------------
  suite["EXP-QUAL-001: first-of-type must be normal (dest fixed nauvis)"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-QUAL", {
      clear_virtual = true,
      clear_mbd_transients = true,
      export_dest_surface_name = "nauvis",
    })

    ensure_all_surfaces()

    local trigger = ensure_surface("vulcanus") -- avoid defeated gate
    local dest = "nauvis"

    -- Ensure roll override does not matter for first-of-type (it must be normal anyway).
    Config.set_export_quality_roll_override("PACK-EXPORT-QUAL", 0.005)

    local before = Oracle.snapshot_detail(PLANETS)
    fire_rocket(trigger)
    local after = Oracle.snapshot_detail(PLANETS)

    assert_added_one_with_quality(
      T, dest, before, after,
      "normal",
      "First-of-type must be normal"
    )

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  suite["EXP-EVO-001: evo reference must be dest_surface (one-shot proof via controlled roll)"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-QUAL", {
      clear_virtual = true,
      clear_mbd_transients = true,
      export_dest_surface_name = "nauvis",
    })

    Config.set_export_force_pick("PACK-EXPORT-QUAL", "manis-small-demolisher-alt", "combat")
    ensure_all_surfaces()

    local trigger = ensure_surface("vulcanus")
    local dest = "nauvis"

    -- We will prove evo reference by making trigger_evo != dest_evo
    -- and forcing a roll r that produces different qualities for those evo bands.
    --
    -- Choose r=0.005:
    -- - evo=0.05 (<0.1) => rare (r < 0.01)
    -- - evo=0.75 (0.7<=evo<0.8) => legendary (r < 0.05)
    --
    -- Expected:
    -- - If implementation correctly uses dest_evo (0.75): legendary
    -- - If it incorrectly uses trigger_evo (0.05): rare
    Config.set_export_evo_override("PACK-EXPORT-QUAL", "vulcanus", 0.05)
    Config.set_export_evo_override("PACK-EXPORT-QUAL", "nauvis", 0.75)

    Config.set_export_quality_roll_override("PACK-EXPORT-QUAL", 0.005)

    -- Step 1: consume first-of-type (must be normal regardless of evo/roll)
    do
      local before1 = Oracle.snapshot_detail(PLANETS)
      fire_rocket(trigger)
      local after1 = Oracle.snapshot_detail(PLANETS)

      assert_added_one_with_quality(
        T, dest, before1, after1,
        "normal",
        "Setup: first-of-type must be normal"
      )
    end

    -- Step 2: second-of-type should use dest_evo and controlled roll => legendary
    do
      local before2 = Oracle.snapshot_detail(PLANETS)
      fire_rocket(trigger)
      local after2 = Oracle.snapshot_detail(PLANETS)

      assert_added_one_with_quality(
        T, dest, before2, after2,
        "legendary",
        "Evo reference must be dest_surface (expected legendary under dest_evo=0.75)"
      )
    end

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  TestRunner.run_suite("MBD.PACK_EXPORT_QUAL", suite)
end

commands.add_command("mbd-pack-export-qual", "Run PACK-EXPORT-QUAL", run_suite)