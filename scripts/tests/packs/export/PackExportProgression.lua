-- scripts/tests/packs/export/PackExportProgression.lua
-- ------------------------------------------------------------
-- Responsibility:
--   PACK-EXPORT-PROGRESSION:
--   Validate export progression candidate pool (selector logic) deterministically.
--   Primary oracle is "candidate pool content" derived from storage flags.
--
-- Notes:
--   - Uses selector._debug_build_pool(surface) (test-only) to avoid randomness.
--   - Flags are stored as:
--       storage.manis_boss_demolisher_flag[surface.name][name] = true
-- ------------------------------------------------------------
-- Test Results:
-- ver.0.1.6 Passed
-- ------------------------------------------------------------
local TestRunner = require("__Manis_TestFramework__/scripts/test/TestRunner")

local Bootstrap = require("scripts.tests.infrastructure.TestBootstrap")
local Selector  = require("scripts.services.boss_demolisher_selector")

local DemolisherNames = require("__Manis_definitions__/scripts/definition/DemolisherNames")

local function ensure_surface(name)
  local s = game.surfaces[name]
  if s then return s end
  return game.create_surface(name, {})
end

local function make_set(list)
  local m = {}
  for _, v in ipairs(list) do m[v] = true end
  return m
end

local function assert_in(T, set, name, msg)
  T.assert(set[name] == true, msg .. " (missing: " .. tostring(name) .. ")")
end

local function assert_not_in(T, set, name, msg)
  T.assert(set[name] ~= true, msg .. " (should not include: " .. tostring(name) .. ")")
end

local function clear_flags(surface_name)
  storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}
  storage.manis_boss_demolisher_flag[surface_name] = {}
end

local function name_for_surface(surface, name)
  -- Match selector's surface policy:
  -- - vulcanus: non-alt
  -- - others : alt
  if type(name) ~= "string" then return name end
  local is_alt = (name:sub(-4) == "-alt")
  if surface and surface.valid and surface.name ~= "vulcanus" then
    return is_alt and name or (name .. "-alt")
  else
    return is_alt and name:sub(1, -5) or name
  end
end

local function set_spawned(surface, name)
  local flag_name = name_for_surface(surface, name)
  storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}
  storage.manis_boss_demolisher_flag[surface.name] = storage.manis_boss_demolisher_flag[surface.name] or {}
  storage.manis_boss_demolisher_flag[surface.name][flag_name] = true
end

local function run_suite()
  local suite = {}

  -- ----------------------------------------------------------
  suite["PROG-001: initial pool contains only small/medium/big/behemoth"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-PROGRESSION", {
      clear_virtual = true,
      clear_mbd_transients = true,
    })

    local surface = ensure_surface("nauvis")
    clear_flags(surface.name)

    local pool = Selector._debug_build_pool(surface)
    local s = make_set(pool)

    assert_in(T, s, DemolisherNames.MANIS_SMALL,    "Initial pool must include MANIS_SMALL")
    assert_in(T, s, DemolisherNames.MANIS_MEDIUM,   "Initial pool must include MANIS_MEDIUM")
    assert_in(T, s, DemolisherNames.MANIS_BIG,      "Initial pool must include MANIS_BIG")
    assert_in(T, s, DemolisherNames.MANIS_BEHEMOTH, "Initial pool must include MANIS_BEHEMOTH")

    assert_not_in(T, s, DemolisherNames.MANIS_SPEEDSTAR_SMALL, "Initial pool must not include speedstar")
    assert_not_in(T, s, DemolisherNames.MANIS_GIGANTIC_SMALL,  "Initial pool must not include gigantic")
    assert_not_in(T, s, DemolisherNames.MANIS_CRAZY_KING,      "Initial pool must not include king")

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  suite["PROG-002: after behemoth spawned, pool includes speedstar_small + gigantic_small"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-PROGRESSION", {
      clear_virtual = true,
      clear_mbd_transients = true,
    })

    local surface = ensure_surface("nauvis")
    clear_flags(surface.name)

    set_spawned(surface, DemolisherNames.MANIS_BEHEMOTH)

    local pool = Selector._debug_build_pool(surface)
    local s = make_set(pool)

    assert_in(T, s, DemolisherNames.MANIS_SPEEDSTAR_SMALL, "Pool must include speedstar_small after behemoth")
    assert_in(T, s, DemolisherNames.MANIS_GIGANTIC_SMALL,  "Pool must include gigantic_small after behemoth")

    assert_in(T, s, DemolisherNames.MANIS_SMALL,    "Pool must still include MANIS_SMALL")
    assert_in(T, s, DemolisherNames.MANIS_MEDIUM,   "Pool must still include MANIS_MEDIUM")
    assert_in(T, s, DemolisherNames.MANIS_BIG,      "Pool must still include MANIS_BIG")
    assert_in(T, s, DemolisherNames.MANIS_BEHEMOTH, "Pool must still include MANIS_BEHEMOTH")

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  suite["PROG-003: after speedstar_small spawned, pool includes speedstar_medium"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-PROGRESSION", {
      clear_virtual = true,
      clear_mbd_transients = true,
    })

    local surface = ensure_surface("nauvis")
    clear_flags(surface.name)

    set_spawned(surface, DemolisherNames.MANIS_BEHEMOTH)
    set_spawned(surface, DemolisherNames.MANIS_SPEEDSTAR_SMALL)

    local pool = Selector._debug_build_pool(surface)
    local s = make_set(pool)

    assert_in(T, s, DemolisherNames.MANIS_SPEEDSTAR_MEDIUM, "Pool must include speedstar_medium after speedstar_small")

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  suite["PROG-004: after gigantic_small spawned, pool includes gigantic_medium"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-PROGRESSION", {
      clear_virtual = true,
      clear_mbd_transients = true,
    })

    local surface = ensure_surface("nauvis")
    clear_flags(surface.name)

    set_spawned(surface, DemolisherNames.MANIS_BEHEMOTH)
    set_spawned(surface, DemolisherNames.MANIS_GIGANTIC_SMALL)

    local pool = Selector._debug_build_pool(surface)
    local s = make_set(pool)

    assert_in(T, s, DemolisherNames.MANIS_GIGANTIC_MEDIUM, "Pool must include gigantic_medium after gigantic_small")

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  suite["PROG-005: after both speedstar_behemoth and gigantic_behemoth spawned, pool includes king"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-PROGRESSION", {
      clear_virtual = true,
      clear_mbd_transients = true,
    })

    local surface = ensure_surface("nauvis")
    clear_flags(surface.name)

    set_spawned(surface, DemolisherNames.MANIS_SPEEDSTAR_BEHEMOTH)
    set_spawned(surface, DemolisherNames.MANIS_GIGANTIC_BEHEMOTH)

    local pool = Selector._debug_build_pool(surface)
    local s = make_set(pool)

    assert_in(T, s, DemolisherNames.MANIS_CRAZY_KING, "Pool must include king after both behemoths")

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  TestRunner.run_suite("MBD.PACK_EXPORT_PROGRESSION", suite)
end

commands.add_command("mbd-pack-export-progression", "Run PACK-EXPORT-PROGRESSION", run_suite)