-- scripts/tests/packs/export/PackExportProgressionWorld.lua
-- ------------------------------------------------------------
-- Responsibility:
--   PACK-EXPORT-PROGRESSION (world-driven):
--   Validate that Export progression is correctly reflected in:
--     (a) world increase on dest surface (physical/virtual)
--     (b) spawned flags stored in storage.manis_boss_demolisher_flag[dest]
--     (c) candidate pool expansion derived from those flags
--
-- Primary oracle:
--   - world state (WorldOracle snapshot/diff)
-- Secondary oracle:
--   - storage flags (manis_boss_demolisher_flag)
--   - selector._debug_build_pool(surface) (deterministic pool inspection)
--
-- Notes:
--   - Uses real rocket-launched event path (RocketEvent.handle).
--   - Uses TestHooks via TestConfig:
--       * export_dest_surface_name (dest fixed)
--       * export_force_pick (deterministic pick)
-- ------------------------------------------------------------
-- Test Results:
-- ver.0.1.6 Passed
-- ------------------------------------------------------------
local TestRunner = require("__Manis_TestFramework__/scripts/test/TestRunner")

local Bootstrap = require("scripts.tests.infrastructure.TestBootstrap")
local Oracle    = require("scripts.tests.infrastructure.WorldOracle")
local Config    = require("scripts.tests.infrastructure.TestConfig")

local Selector  = require("scripts.services.boss_demolisher_selector")
local RocketEvent = require("scripts.events.on_rocket_launched")

local DemolisherNames = require("__Manis_definitions__/scripts/definition/DemolisherNames")

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

local function ensure_flag_store(surface_name)
  storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}
  storage.manis_boss_demolisher_flag[surface_name] = storage.manis_boss_demolisher_flag[surface_name] or {}
  return storage.manis_boss_demolisher_flag[surface_name]
end

local function clear_flags(surface_name)
  storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}
  storage.manis_boss_demolisher_flag[surface_name] = {}
end

local function pool_set(surface)
  local pool = Selector._debug_build_pool(surface)
  local s = {}
  for _, n in ipairs(pool) do s[n] = true end
  return s
end

local function assert_in(T, set, name, msg)
  T.assert(set[name] == true, msg .. " (missing: " .. tostring(name) .. ")")
end

local function assert_not_in(T, set, name, msg)
  T.assert(set[name] ~= true, msg .. " (should not include: " .. tostring(name) .. ")")
end

local function export_force(surface_trigger, dest_surface_name, entity_name, category)
  Config.set_export_dest_surface_name("PACK-EXPORT-PROGRESSION", dest_surface_name)
  Config.set_export_force_pick("PACK-EXPORT-PROGRESSION", entity_name, category)
  fire_rocket(surface_trigger)
end

local function assert_world_increase_on_dest(T, dest_name, before, after, msg)
  local d = Oracle.diff(before, after)
  T.assert(Oracle.any_increase_on(d, dest_name),
    msg .. " (expected increase on dest=" .. dest_name ..
    " but got phy=" .. d[dest_name].phy .. " virt=" .. d[dest_name].virt .. ")")
end

-- ------------------------------------------------------------
local function run_suite()
  local suite = {}

  -- ----------------------------------------------------------
  suite["PROG-001: export sets spawned flag by entity_name (no -alt normalization)"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-PROGRESSION", {
      clear_virtual = true,
      clear_mbd_transients = true,
      export_dest_surface_name = "nauvis",
    })
    Config.set_export_cap_override("PACK-EXPORT-PROGRESSION", 9999, 9999)

    ensure_all_surfaces()

    local trigger = ensure_surface("vulcanus")
    local dest = "nauvis"
    local dest_surface = ensure_surface(dest)

    -- Clean dest flags
    clear_flags(dest)

    local pick_alt = DemolisherNames.MANIS_SMALL_ALT
    Config.set_export_force_pick("PACK-EXPORT-PROGRESSION", pick_alt, "combat")

    local before = Oracle.snapshot(PLANETS)
    fire_rocket(trigger)
    local after = Oracle.snapshot(PLANETS)

    assert_world_increase_on_dest(T, dest, before, after, "Export must increase world on dest for forced pick")

    local per_surface = ensure_flag_store(dest)

    -- No normalization: flags are keyed by exact entity_name
    T.assert(per_surface[pick_alt] == true,
      "Spawned flag must be recorded by entity_name. expected flag[" .. tostring(pick_alt) .. "]=true")

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  suite["PROG-002: after behemoth spawned, pool includes speedstar_small and gigantic_small"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-PROGRESSION", {
      clear_virtual = true,
      clear_mbd_transients = true,
      export_dest_surface_name = "nauvis",
    })
    Config.set_export_cap_override("PACK-EXPORT-PROGRESSION", 9999, 9999)

    ensure_all_surfaces()

    local trigger = ensure_surface("vulcanus")
    local dest = "nauvis"
    local dest_surface = ensure_surface(dest)

    clear_flags(dest)

    -- Force export behemoth to set progression flag
    Config.set_export_force_pick("PACK-EXPORT-PROGRESSION", DemolisherNames.MANIS_BEHEMOTH_ALT, "combat")

    local before = Oracle.snapshot(PLANETS)
    fire_rocket(trigger)
    local after = Oracle.snapshot(PLANETS)

    assert_world_increase_on_dest(T, dest, before, after, "Behemoth export must increase world on dest")

    local s = pool_set(dest_surface)
    assert_in(T, s, DemolisherNames.MANIS_SPEEDSTAR_SMALL, "Pool must include speedstar_small after behemoth spawned")
    assert_in(T, s, DemolisherNames.MANIS_GIGANTIC_SMALL,  "Pool must include gigantic_small after behemoth spawned")

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  suite["PROG-003: after speedstar_small spawned, pool includes speedstar_medium"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-PROGRESSION", {
      clear_virtual = true,
      clear_mbd_transients = true,
      export_dest_surface_name = "nauvis",
    })
    Config.set_export_cap_override("PACK-EXPORT-PROGRESSION", 9999, 9999)

    ensure_all_surfaces()

    local trigger = ensure_surface("vulcanus")
    local dest = "nauvis"
    local dest_surface = ensure_surface(dest)

    clear_flags(dest)

    -- Step A: behemoth (unlock branch)
    Config.set_export_force_pick("PACK-EXPORT-PROGRESSION", DemolisherNames.MANIS_BEHEMOTH_ALT, "combat")
    do
      local before = Oracle.snapshot(PLANETS)
      fire_rocket(trigger)
      local after = Oracle.snapshot(PLANETS)
      assert_world_increase_on_dest(T, dest, before, after, "Setup: behemoth must export")
    end

    -- Step B: speedstar_small
    Config.set_export_force_pick("PACK-EXPORT-PROGRESSION", DemolisherNames.MANIS_SPEEDSTAR_SMALL_ALT, "combat")
    do
      local before = Oracle.snapshot(PLANETS)
      fire_rocket(trigger)
      local after = Oracle.snapshot(PLANETS)
      assert_world_increase_on_dest(T, dest, before, after, "Setup: speedstar_small must export")
    end

    local s = pool_set(dest_surface)
    assert_in(T, s, DemolisherNames.MANIS_SPEEDSTAR_MEDIUM, "Pool must include speedstar_medium after speedstar_small spawned")

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  suite["PROG-004: after gigantic_small spawned, pool includes gigantic_medium"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-PROGRESSION", {
      clear_virtual = true,
      clear_mbd_transients = true,
      export_dest_surface_name = "nauvis",
    })
    Config.set_export_cap_override("PACK-EXPORT-PROGRESSION", 9999, 9999)

    ensure_all_surfaces()

    local trigger = ensure_surface("vulcanus")
    local dest = "nauvis"
    local dest_surface = ensure_surface(dest)

    clear_flags(dest)

    -- Step A: behemoth (unlock branch)
    Config.set_export_force_pick("PACK-EXPORT-PROGRESSION", DemolisherNames.MANIS_BEHEMOTH_ALT, "combat")
    do
      local before = Oracle.snapshot(PLANETS)
      fire_rocket(trigger)
      local after = Oracle.snapshot(PLANETS)
      assert_world_increase_on_dest(T, dest, before, after, "Setup: behemoth must export")
    end

    -- Step B: gigantic_small (fatal)
    Config.set_export_force_pick("PACK-EXPORT-PROGRESSION", DemolisherNames.MANIS_GIGANTIC_SMALL_ALT, "fatal")
    do
      local before = Oracle.snapshot(PLANETS)
      fire_rocket(trigger)
      local after = Oracle.snapshot(PLANETS)
      assert_world_increase_on_dest(T, dest, before, after, "Setup: gigantic_small must export")
    end

    local s = pool_set(dest_surface)
    assert_in(T, s, DemolisherNames.MANIS_GIGANTIC_MEDIUM, "Pool must include gigantic_medium after gigantic_small spawned")

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  suite["PROG-005: after both speedstar_behemoth and gigantic_behemoth spawned, pool includes king"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-PROGRESSION", {
      clear_virtual = true,
      clear_mbd_transients = true,
      export_dest_surface_name = "nauvis",
    })
    Config.set_export_cap_override("PACK-EXPORT-PROGRESSION", 9999, 9999)

    ensure_all_surfaces()

    local trigger = ensure_surface("vulcanus")
    local dest = "nauvis"
    local dest_surface = ensure_surface(dest)

    clear_flags(dest)

    -- Prereq: branch unlock + speedstar line
    export_force(trigger, dest, DemolisherNames.MANIS_BEHEMOTH_ALT, "combat")

    export_force(trigger, dest, DemolisherNames.MANIS_SPEEDSTAR_SMALL_ALT, "combat")
    export_force(trigger, dest, DemolisherNames.MANIS_SPEEDSTAR_MEDIUM_ALT, "combat")
    export_force(trigger, dest, DemolisherNames.MANIS_SPEEDSTAR_BIG_ALT, "combat")
    export_force(trigger, dest, DemolisherNames.MANIS_SPEEDSTAR_BEHEMOTH_ALT, "combat")

    -- gigantic line
    export_force(trigger, dest, DemolisherNames.MANIS_GIGANTIC_SMALL_ALT, "fatal")
    export_force(trigger, dest, DemolisherNames.MANIS_GIGANTIC_MEDIUM_ALT, "fatal")
    export_force(trigger, dest, DemolisherNames.MANIS_GIGANTIC_BIG_ALT, "fatal")
    export_force(trigger, dest, DemolisherNames.MANIS_GIGANTIC_BEHEMOTH_ALT, "fatal")

    local s = pool_set(dest_surface)
    assert_in(T, s, DemolisherNames.MANIS_CRAZY_KING, "Pool must include king after both behemoth lines spawned")

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  suite["PROG-006: progression is independent per dest_surface"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-PROGRESSION", {
      clear_virtual = true,
      clear_mbd_transients = true,
    })
    Config.set_export_cap_override("PACK-EXPORT-PROGRESSION", 9999, 9999)

    ensure_all_surfaces()

    local trigger = ensure_surface("vulcanus")

    -- Clean both
    clear_flags("nauvis")
    clear_flags("gleba")

    -- Advance only on nauvis: export behemoth
    Config.set_export_dest_surface_name("PACK-EXPORT-PROGRESSION", "nauvis")
    Config.set_export_force_pick("PACK-EXPORT-PROGRESSION", DemolisherNames.MANIS_BEHEMOTH_ALT, "combat")
    do
      local before = Oracle.snapshot(PLANETS)
      fire_rocket(trigger)
      local after = Oracle.snapshot(PLANETS)
      assert_world_increase_on_dest(T, "nauvis", before, after, "Behemoth export must affect nauvis")
    end

    -- Verify nauvis pool expanded
    local nauvis_surface = ensure_surface("nauvis")
    local sn = pool_set(nauvis_surface)
    assert_in(T, sn, DemolisherNames.MANIS_SPEEDSTAR_SMALL, "nauvis pool must include speedstar_small after behemoth")

    -- Verify gleba pool NOT expanded (independent)
    local gleba_surface = ensure_surface("gleba")
    local sg = pool_set(gleba_surface)
    assert_not_in(T, sg, DemolisherNames.MANIS_SPEEDSTAR_SMALL, "gleba pool must not include speedstar_small (independent progression)")

    Bootstrap.end_pack()
  end

  TestRunner.run_suite("MBD.PACK_EXPORT_PROGRESSION_WORLD", suite)
end

commands.add_command("mbd-pack-export-progression-world", "Run PACK-EXPORT-PROGRESSION (world)", run_suite)