-- scripts/tests/packs/export/PackExportCapEdge.lua
-- ------------------------------------------------------------
-- Responsibility:
--   PACK-EXPORT-CAP-EDGE:
--   Deterministic boundary tests for Export cap suppression.
--
-- Cap model (confirmed):
--   - combat_cap: cap for (combat + fatal) total
--   - fatal_cap : cap for (fatal only)
--
-- Primary oracle: world state (no increase on dest when capped).
-- ------------------------------------------------------------
-- Test Results:
-- ver.0.1.6 Passed
-- ------------------------------------------------------------
local TestRunner = require("__Manis_TestFramework__/scripts/test/TestRunner")

local Bootstrap = require("scripts.tests.infrastructure.TestBootstrap")
local Oracle    = require("scripts.tests.infrastructure.WorldOracle")
local Config    = require("scripts.tests.infrastructure.TestConfig")

local VirtualMgr = require("__Manis_lib__/scripts/managers/VirtualEntityManager")
local DemolisherNames = require("__Manis_definitions__/scripts/definition/DemolisherNames")

local RocketEvent = require("scripts.events.on_rocket_launched")

local PLANETS = { "nauvis", "gleba", "fulgora", "vulcanus", "aquilo" }

local function ensure_surface(name)
  local s = game.surfaces[name]
  if s then return s end
  return game.create_surface(name, {})
end

local function ensure_all_surfaces()
  for _, n in ipairs(PLANETS) do ensure_surface(n) end
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

local function enqueue_virtual(surface, name, category, n)
  -- Put them far from origin; exact positions don't matter for cap counting.
  -- Keep IDs deterministic by not mixing other enqueues in the same test.
  local base_x, base_y = -1000, -1000
  for i = 1, n do
    local pos = { x = base_x + i, y = base_y }
    VirtualMgr.enqueue(surface, nil, pos, {
      name = name,
      quality = "normal",
      force = "enemy",
      category = category, -- used by adapters; cap counting should use DemolisherNames sets anyway
    })
  end
end

-- Minimal cleanup for this pack (virtual cleared by Bootstrap; physical is not expected here but clear anyway)
local function clear_virtual(surface)
  -- Bootstrap.clear_virtual nukes the whole store; no per-surface delete API.
  -- So this is intentionally empty.
end

local function run_suite()
  local suite = {}

  -- ----------------------------------------------------------
  suite["CAP-EDGE-001: total=cap-1 => export increases by +1 on dest"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-CAP-EDGE", {
      clear_virtual = true,
      clear_mbd_transients = true,
      export_dest_surface_name = "nauvis",
    })

    ensure_all_surfaces()

    local trigger = ensure_surface("vulcanus")
    local dest_surface = ensure_surface("nauvis")
    local dest_name = "nauvis"

    -- Fix caps small for fast boundary tests.
    -- Example: combat_cap=3, fatal_cap=2
    Config.set_export_cap_override("PACK-EXPORT-CAP-EDGE", 3, 0)

    -- Force pick a COMBAT entity so the exported one is combat.
    Config.set_export_force_pick("PACK-EXPORT-CAP-EDGE", DemolisherNames.MANIS_SMALL_ALT, "combat")

    -- Pre-fill total = cap-1 (2 combat, 0 fatal) -> should allow +1.
    enqueue_virtual(dest_surface, DemolisherNames.MANIS_SMALL_ALT, "combat", 2)

    local before = Oracle.snapshot(PLANETS)
    fire_rocket(trigger)
    local after = Oracle.snapshot(PLANETS)
    local d = Oracle.diff(before, after)

    T.assert(Oracle.any_increase_on(d, dest_name),
      "Expected +1 increase when total=cap-1, but got diff phy=" .. d[dest_name].phy .. " virt=" .. d[dest_name].virt)

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  suite["CAP-EDGE-002: total=cap => export suppressed (no increase)"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-CAP-EDGE", {
      clear_virtual = true,
      clear_mbd_transients = true,
      export_dest_surface_name = "nauvis",
    })

    ensure_all_surfaces()

    local trigger = ensure_surface("vulcanus")
    local dest_surface = ensure_surface("nauvis")
    local dest_name = "nauvis"

    Config.set_export_cap_override("PACK-EXPORT-CAP-EDGE", 3, 0)
    Config.set_export_force_pick("PACK-EXPORT-CAP-EDGE", DemolisherNames.MANIS_SMALL_ALT, "combat")

    -- Pre-fill total = cap (3 combat, 0 fatal) -> should suppress
    enqueue_virtual(dest_surface, DemolisherNames.MANIS_SMALL_ALT, "combat", 3)

    local before = Oracle.snapshot(PLANETS)
    fire_rocket(trigger)
    local after = Oracle.snapshot(PLANETS)
    local d = Oracle.diff(before, after)

    T.assert(not Oracle.any_increase_on(d, dest_name),
      "Expected no increase when total=cap, but got diff phy=" .. d[dest_name].phy .. " virt=" .. d[dest_name].virt)

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  suite["CAP-EDGE-003: total>cap => export suppressed (no increase)"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-CAP-EDGE", {
      clear_virtual = true,
      clear_mbd_transients = true,
      export_dest_surface_name = "nauvis",
    })

    ensure_all_surfaces()

    local trigger = ensure_surface("vulcanus")
    local dest_surface = ensure_surface("nauvis")
    local dest_name = "nauvis"

    Config.set_export_cap_override("PACK-EXPORT-CAP-EDGE", 3, 0)
    Config.set_export_force_pick("PACK-EXPORT-CAP-EDGE", DemolisherNames.MANIS_SMALL_ALT, "combat")

    -- Pre-fill total = cap+1 (4 combat) -> suppress
    enqueue_virtual(dest_surface, DemolisherNames.MANIS_SMALL_ALT, "combat", 4)

    local before = Oracle.snapshot(PLANETS)
    fire_rocket(trigger)
    local after = Oracle.snapshot(PLANETS)
    local d = Oracle.diff(before, after)

    T.assert(not Oracle.any_increase_on(d, dest_name),
      "Expected no increase when total>cap, but got diff phy=" .. d[dest_name].phy .. " virt=" .. d[dest_name].virt)

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  -- Extra: fatal_cap boundary (optional but cheap)


  TestRunner.run_suite("MBD.PACK_EXPORT_CAP_EDGE", suite)
end

commands.add_command("mbd-pack-export-cap-edge", "Run PACK-EXPORT-CAP-EDGE", run_suite)