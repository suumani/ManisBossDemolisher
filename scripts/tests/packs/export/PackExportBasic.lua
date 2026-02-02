-- scripts/tests/packs/export/PackExportBasic.lua
-- ------------------------------------------------------------
-- Responsibility:
--   PACK-EXPORT-BASIC:
--   Game-behavior regression tests for Export.
--   Primary oracle is world state (physical entities or virtual entries).
--
-- Notes:
--   - Entry point is unified to RocketEvent.handle(...) to match real event flow.
--   - Defeated flag is treated as As-Is storage gate (documented).
--     (Future: move to TestHooks/TestConfig abstraction.)
-- ------------------------------------------------------------
-- Test Results:
-- ver.0.1.6 Passed
-- ------------------------------------------------------------

local TestRunner = require("__Manis_TestFramework__/scripts/test/TestRunner")

local Bootstrap = require("scripts.tests.infrastructure.TestBootstrap")
local Oracle    = require("scripts.tests.infrastructure.WorldOracle")
local Config    = require("scripts.tests.infrastructure.TestConfig")

-- IMPORTANT: require at parse time (control.lua parsing), not during test execution.
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

local function ensure_all_surfaces()
  for _, n in ipairs(PLANETS) do
    ensure_surface(n)
  end
end

-- As-Is defeated flag gate (documented in specs; direct storage touch is intentional here)
local function set_defeated(surface_name, value)
  storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}
  storage.manis_boss_demolisher_flag[surface_name] = storage.manis_boss_demolisher_flag[surface_name] or {}

  -- Only true is meaningful; false means "unset" (nil).
  if value == true then
    storage.manis_boss_demolisher_flag[surface_name].defeated = true
  else
    storage.manis_boss_demolisher_flag[surface_name].defeated = nil
  end
end

-- ------------------------------------------------------------
-- suite
-- ------------------------------------------------------------
local function run_suite()
  local suite = {}

  -- ----------------------------------------------------------
  suite["EXP-BASIC-001: vulcanus special => export occurs even if defeated=false"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-BASIC", {
      clear_virtual = true,
      clear_mbd_transients = true,
      export_dest_surface_name = "nauvis", -- absorb randomness
    })

    ensure_all_surfaces()

    local trigger = ensure_surface("vulcanus")
    local dest = "nauvis"

    -- Explicitly mark defeated=false to prove Vulcanus special rule
    set_defeated("vulcanus", false)

    local before = Oracle.snapshot(PLANETS)

    fire_rocket(trigger)

    local after = Oracle.snapshot(PLANETS)
    local d = Oracle.diff(before, after)

    T.assert(Oracle.any_increase_on(d, dest),
      "Vulcanus must allow export regardless of defeated flag; " ..
      "expected increase on dest=" .. dest ..
      " but got phy=" .. d[dest].phy .. " virt=" .. d[dest].virt)

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  suite["EXP-BASIC-002: non-vulcanus & defeated=false => no export (no world change)"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-BASIC", {
      clear_virtual = true,
      clear_mbd_transients = true,
    })

    ensure_all_surfaces()

    local trigger = ensure_surface("nauvis")

    -- Non-vulcanus requires defeated=true
    set_defeated("nauvis", false)

    local before = Oracle.snapshot(PLANETS)

    fire_rocket(trigger)

    local after = Oracle.snapshot(PLANETS)
    local d = Oracle.diff(before, after)

    T.assert(not Oracle.any_increase_anywhere(d),
      "Non-vulcanus & defeated=false must not cause any export world change")

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  suite["EXP-BASIC-003: non-vulcanus & defeated=true => export occurs"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-BASIC", {
      clear_virtual = true,
      clear_mbd_transients = true,
      export_dest_surface_name = "nauvis",
    })

    ensure_all_surfaces()

    local trigger = ensure_surface("nauvis")
    local dest = "nauvis"

    -- Gate open
    set_defeated("nauvis", true)

    local before = Oracle.snapshot(PLANETS)

    fire_rocket(trigger)

    local after = Oracle.snapshot(PLANETS)
    local d = Oracle.diff(before, after)

    T.assert(Oracle.any_increase_on(d, dest),
      "defeated=true must allow export; expected increase on dest=" .. dest ..
      " but got phy=" .. d[dest].phy .. " virt=" .. d[dest].virt)

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  suite["EXP-BASIC-004: cap reached => export suppressed (no world increase)"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-BASIC", {
      clear_virtual = true,
      clear_mbd_transients = true,
      export_dest_surface_name = "nauvis",
    })

    ensure_all_surfaces()

    local trigger = ensure_surface("vulcanus")
    local dest = "nauvis"

    -- Force cap to zero so any export must be suppressed
    -- (As-Is API: arguments documented here for clarity)
    --   set_export_cap_override(pack_id, cap_phy, cap_virt)
    Config.set_export_cap_override("PACK-EXPORT-BASIC", 0, 0)

    local before = Oracle.snapshot(PLANETS)

    fire_rocket(trigger)

    local after = Oracle.snapshot(PLANETS)
    local d = Oracle.diff(before, after)

    T.assert(not Oracle.any_increase_on(d, dest),
      "cap override must suppress export; no increase expected on dest=" .. dest ..
      " but got phy=" .. d[dest].phy .. " virt=" .. d[dest].virt)

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  suite["EXP-BASIC-VIRT-001: ungenerated area => virtual increases and physical does not"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-BASIC", {
      clear_virtual = true,
      clear_mbd_transients = true,
      export_dest_surface_name = "nauvis",
    })

    ensure_all_surfaces()

    local trigger = ensure_surface("vulcanus")
    local dest = "nauvis"

    -- 重要：前のケースで cap=0 を入れているので、ここで必ず戻す
    Config.set_export_cap_override("PACK-EXPORT-BASIC", 9999, 9999)

    -- 未生成を狙う固定座標
    Config.set_export_spawn_position("PACK-EXPORT-BASIC", dest, { x = 200000, y = 200000 })

    local before = Oracle.snapshot(PLANETS)
    fire_rocket(trigger)
    local after = Oracle.snapshot(PLANETS)
    local d = Oracle.diff(before, after)

    T.assert(d[dest].phy == 0,
      "Expected no physical increase on dest=" .. dest .. " but got phy=" .. tostring(d[dest].phy))
    T.assert(d[dest].virt == 1,
      "Expected virtual +1 on dest=" .. dest .. " but got virt=" .. tostring(d[dest].virt))

    Bootstrap.end_pack()
  end

  -- ----------------------------------------------------------
  suite["EXP-BASIC-PHY-001: generated chunk => physical +1 and virtual +0"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-BASIC", {
      clear_virtual = true,
      clear_mbd_transients = true,
      export_dest_surface_name = "nauvis",
    })

    ensure_all_surfaces()

    local trigger = ensure_surface("vulcanus") -- gate回避
    local dest = "nauvis"
    local dest_surface = ensure_surface(dest)

    -- cap override 残留対策
    Config.set_export_cap_override("PACK-EXPORT-BASIC", 9999, 9999)

    -- ここは「生成済み」をテスト内で確定してから使う
    local pos = { x = 0, y = 0 }
    local function chunk_pos(p)
      return { x = math.floor(p.x / 32), y = math.floor(p.y / 32) }
    end

    -- 前提：このチャンクは生成済みであること
    T.assert(dest_surface.is_chunk_generated(chunk_pos(pos)) == true,
      "Precondition failed: expected generated chunk at pos={0,0}")

    Config.set_export_spawn_position("PACK-EXPORT-BASIC", dest, pos)

    local before = Oracle.snapshot(PLANETS)
    fire_rocket(trigger)
    local after = Oracle.snapshot(PLANETS)
    local d = Oracle.diff(before, after)

    T.assert(d[dest].virt == 0,
      "Expected virtual +0 on generated chunk but got virt=" .. tostring(d[dest].virt))
    T.assert(d[dest].phy == 1,
      "Expected physical +1 on generated chunk but got phy=" .. tostring(d[dest].phy))

    Bootstrap.end_pack()
  end
  -- ----------------------------------------------------------

suite["EXP-BASIC-CHUNK-001: same position switches from virtual to physical after chunk generation"] = function(T)
  Bootstrap.start_pack("PACK-EXPORT-BASIC", {
    clear_virtual = true,
    clear_mbd_transients = true,
    export_dest_surface_name = "nauvis",
  })

  ensure_all_surfaces()

  local trigger = ensure_surface("vulcanus")
  local dest = "nauvis"
  local dest_surface = ensure_surface(dest)

  Config.set_export_cap_override("PACK-EXPORT-BASIC", 9999, 9999)

  local pos = { x = 100000, y = 100000 }
  Config.set_export_spawn_position("PACK-EXPORT-BASIC", dest, pos)

  local function chunk_pos(p)
    return { x = math.floor(p.x / 32), y = math.floor(p.y / 32) }
  end

  -- Precondition: ungenerated
  T.assert(dest_surface.is_chunk_generated(chunk_pos(pos)) == false,
    "Precondition failed: expected ungenerated chunk at pos={100000,100000}")

  -- Step 1: ungenerated => virtual
  do
    local before = Oracle.snapshot(PLANETS)
    fire_rocket(trigger)
    local after = Oracle.snapshot(PLANETS)
    local d = Oracle.diff(before, after)

    T.assert(d[dest].phy == 0, "Expected phy=0 (ungenerated) but got " .. tostring(d[dest].phy))
    T.assert(d[dest].virt == 1, "Expected virt=+1 (ungenerated) but got " .. tostring(d[dest].virt))
  end

  -- Generate chunk
  dest_surface.request_to_generate_chunks(pos, 1)
  dest_surface.force_generate_chunk_requests()

  T.assert(dest_surface.is_chunk_generated(chunk_pos(pos)) == true,
    "Chunk generation failed: expected generated chunk at pos={100000,100000}")

  -- Step 2: generated => physical
  do
    local before = Oracle.snapshot(PLANETS)
    fire_rocket(trigger)
    local after = Oracle.snapshot(PLANETS)
    local d = Oracle.diff(before, after)

    T.assert(d[dest].virt == 0, "Expected virt=0 (generated) but got " .. tostring(d[dest].virt))
    T.assert(d[dest].phy == 1, "Expected phy=+1 (generated) but got " .. tostring(d[dest].phy))
  end

  Bootstrap.end_pack()
end


  TestRunner.run_suite("MBD.PACK_EXPORT_BASIC", suite)
end

commands.add_command("mbd-pack-export-basic", "Run PACK-EXPORT-BASIC", run_suite)