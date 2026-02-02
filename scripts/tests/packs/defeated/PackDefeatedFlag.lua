-- scripts/tests/packs/defeated/PackDefeatedFlag.lua
-- ------------------------------------------------------------
-- Responsibility:
--   PACK-DEFEATED-FLAG:
--   Validate that Defeated flag is set by physical demolisher defeat event.
--
-- Primary oracle:
--   - storage.manis_boss_demolisher_flag[surface].defeated == true
--
-- Covered specs:
--   - 02_PlanetStateModel.md: PP-DEF-001
--   - 04_BossClasses.md: DEF-SCOPE-001 (scope via DemolisherNames.ALL)
--   - 90_Observability.md: OBS-DEF-001 (log is not asserted here; world state is primary)
--
-- Notes:
--   - This pack uses deferred assertion (next tick) because on_entity_died may apply after the kill tick.
--   - No per-test nth_tick registration is used; relies on TestRunner.defer_in_ticks + centralized pump.
-- ------------------------------------------------------------
-- Test Results:
-- ver.0.1.6 Passed
-- ------------------------------------------------------------

local TestRunner = require("__Manis_TestFramework__/scripts/test/TestRunner")

local Bootstrap = require("scripts.tests.infrastructure.TestBootstrap")
local DemolisherNames = require("__Manis_definitions__/scripts/definition/DemolisherNames")
local Deferred = require("scripts.tests.infrastructure.DeferredTestRunner")

local PLANETS = { "nauvis", "gleba", "fulgora", "vulcanus", "aquilo" }

local function kill_entity(e)
  if not e then return end
  local attacker = game.forces.player

  -- Prefer die() if available; fallback to massive damage.
  if e.valid and e.die then
    e.die(attacker)
    return
  end
  if e.valid and e.damage then
    e.damage(1000000, attacker, "physical")
  end
end

local function ensure_surface(name)
  local s = game.surfaces[name]
  if s then return s end
  return game.create_surface(name, {})
end

local function ensure_all_surfaces()
  for _, n in ipairs(PLANETS) do ensure_surface(n) end
end

local function clear_defeated(surface_name)
  storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}
  storage.manis_boss_demolisher_flag[surface_name] = storage.manis_boss_demolisher_flag[surface_name] or {}
  storage.manis_boss_demolisher_flag[surface_name].defeated = nil
end

local function is_defeated(surface_name)
  return storage.manis_boss_demolisher_flag
     and storage.manis_boss_demolisher_flag[surface_name]
     and storage.manis_boss_demolisher_flag[surface_name].defeated == true
end

local function spawn_one_demolisher(surface, name, pos)
  pos = pos or { x = 200, y = 0 }
  return surface.create_entity{
    name = name,
    position = pos,
    force = "enemy",
    quality = "normal"
  }
end

local function run_suite()
  local suite = {}

  suite["DEF-001: defeating a demolisher sets defeated=true on that surface"] = function(T)
    Bootstrap.start_pack("PACK-DEFEATED-FLAG", {
      clear_virtual = true,
      clear_mbd_transients = true,
    })

    ensure_all_surfaces()

    local surface_name = "nauvis"
    local s = ensure_surface(surface_name)

    clear_defeated(surface_name)
    T.assert(not is_defeated(surface_name), "Precondition: defeated must be nil/false")

    local e = spawn_one_demolisher(s, DemolisherNames.MANIS_SMALL_ALT, { x = 300, y = 0 })
    T.assert(e and e.valid, "Demolisher must be spawned for defeat test")

    kill_entity(e)

    -- Defer assertion to next tick (event may apply after current tick)
    T.defer_in_ticks(1, function(T2)
      T2.assert(is_defeated(surface_name), "Defeated flag must become true after demolisher death (next tick)")
    end)

    Bootstrap.end_pack()
  end

  suite["DEF-002: defeated does not propagate to other surfaces"] = function(T)
    Bootstrap.start_pack("PACK-DEFEATED-FLAG", {
      clear_virtual = true,
      clear_mbd_transients = true,
    })

    ensure_all_surfaces()

    local s1 = "nauvis"
    local s2 = "gleba"
    local surf1 = ensure_surface(s1)
    local surf2 = ensure_surface(s2) -- exists; just to be explicit

    clear_defeated(s1)
    clear_defeated(s2)

    local e = spawn_one_demolisher(surf1, DemolisherNames.MANIS_SMALL_ALT, { x = 320, y = 0 })
    T.assert(e and e.valid, "Demolisher must be spawned on nauvis")
    kill_entity(e)

    T.defer_in_ticks(1, function(T2)
      T2.assert(is_defeated(s1), "Defeated must be true on nauvis after defeat (next tick)")
      T2.assert(not is_defeated(s2), "Defeated must remain false on gleba (no propagation)")
    end)

    Bootstrap.end_pack()
  end

suite["DEF-003B: defeated stays true after another defeat (next tick)"] = function(T)
  Bootstrap.start_pack("PACK-DEFEATED-FLAG", {
    clear_virtual = true,
    clear_mbd_transients = true,
  })

  ensure_all_surfaces()

  local surface_name = "nauvis"
  local s = ensure_surface(surface_name)

  clear_defeated(surface_name)

  -- Precondition: defeated is already true on this surface.
  storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}
  storage.manis_boss_demolisher_flag[surface_name] = storage.manis_boss_demolisher_flag[surface_name] or {}
  storage.manis_boss_demolisher_flag[surface_name].defeated = true

  -- Second defeat should not change defeated back to false.
  local e2 = spawn_one_demolisher(s, DemolisherNames.MANIS_MEDIUM_ALT, { x = 360, y = 0 })
  T.assert(e2 and e2.valid, "Demolisher must be spawned")
  kill_entity(e2)

  -- Verify after event processing tick
  T.defer_in_ticks(1, function(T2)
    T2.assert(is_defeated(surface_name), "Defeated must stay true after subsequent defeats (next tick)")
  end)

  Bootstrap.end_pack()
end

  Deferred.run_suite("MBD.PACK_DEFEATED_FLAG", suite)
end

commands.add_command("mbd-pack-defeated-flag", "Run PACK-DEFEATED-FLAG", run_suite)