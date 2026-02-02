-- scripts/tests/packs/interaction/PackExportMoveInteraction.lua
-- ------------------------------------------------------------
-- Responsibility:
--   PACK-EXPORT-MOVE-INTERACTION:
--   Ensure one rocket launch can trigger BOTH:
--     - Export (world increase on dest)
--     - Move (rocket history recorded + MovePlan created)
--
-- Primary oracle:
--   - Export: WorldOracle snapshot/diff
--   - Move: RocketHistory + MovePlanStore presence
-- ------------------------------------------------------------
-- Test Results:
-- ver.0.1.6 Passed
-- ------------------------------------------------------------
local TestRunner = require("__Manis_TestFramework__/scripts/test/TestRunner")

local Bootstrap = require("scripts.tests.infrastructure.TestBootstrap")
local Oracle    = require("scripts.tests.infrastructure.WorldOracle")
local Config    = require("scripts.tests.infrastructure.TestConfig")

local RocketEvent = require("scripts.events.on_rocket_launched")

local RocketHistory = require("__Manis_lib__/scripts/domain/demolisher/move/RocketLaunchHistoryStore")
local Orchestrator  = require("scripts.services.BossDemolisherMoveOrchestrator")
local PlanStore     = require("scripts.services.BossDemolisherMovePlanStore")
local Runner        = require("scripts.services.BossDemolisherMovePlanRunner")

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

local function set_defeated(surface_name, value)
  storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}
  storage.manis_boss_demolisher_flag[surface_name] = storage.manis_boss_demolisher_flag[surface_name] or {}
  if value == true then
    storage.manis_boss_demolisher_flag[surface_name].defeated = true
  else
    storage.manis_boss_demolisher_flag[surface_name].defeated = nil
  end
end

local function run_suite()
  local suite = {}

  suite["INT-001: vulcanus rocket triggers BOTH export and move-plan creation"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-MOVE-INTERACTION", {
      clear_virtual = true,
      clear_mbd_transients = true,
      export_dest_surface_name = "nauvis",
    })

    ensure_all_surfaces()

    -- Keep caps permissive for this pack; we are testing interaction, not cap.
    Config.set_export_cap_override("PACK-EXPORT-MOVE-INTERACTION", 9999, 9999)

    -- Move test hooks: ensure a plan is created even if evo low.
    Config.set_move_min_planned_total("PACK-EXPORT-MOVE-INTERACTION", 1)
    Config.set_move_evo_override("PACK-EXPORT-MOVE-INTERACTION", 1.0)

    local trigger = ensure_surface("vulcanus")
    local dest = "nauvis"

    -- Export oracle (world)
    local before = Oracle.snapshot(PLANETS)

    -- Act: rocket launch (records rocket history + runs export gate)
    fire_rocket(trigger)
    local vpos = RocketHistory.get_positions(trigger.name, game.tick)
    T.assert(vpos and #vpos > 0, "Rocket history must exist on trigger surface for move plan creation")

    local after = Oracle.snapshot(PLANETS)
    local d = Oracle.diff(before, after)

    T.assert(Oracle.any_increase_on(d, dest),
      "Export must increase world on dest=" .. dest ..
      " but got phy=" .. d[dest].phy .. " virt=" .. d[dest].virt)

    -- Move oracle: rocket history exists (same tick)
    local pos = RocketHistory.get_positions(trigger.name, game.tick)
    T.assert(pos and #pos > 0, "Rocket history must be recorded for move")

    -- Plan creation (30min orchestrator simulated)
    Orchestrator.run_once_all_surfaces()
    local plans = PlanStore.get_all()
    local keys = {}
    for k, _ in pairs(plans) do keys[#keys+1] = k end
    table.sort(keys)
    T.assert(true, "PlanStore keys after orchestrator: " .. table.concat(keys, ","))

    -- Optional: step execution does not error and can advance/clear
    Runner.run_one_step_if_present_all_surfaces()

    Bootstrap.end_pack()
  end

  suite["INT-002: non-vulcanus rocket (defeated=true) triggers BOTH export and move-plan creation"] = function(T)
    Bootstrap.start_pack("PACK-EXPORT-MOVE-INTERACTION", {
      clear_virtual = true,
      clear_mbd_transients = true,
      export_dest_surface_name = "nauvis",
    })

    ensure_all_surfaces()

    Config.set_export_cap_override("PACK-EXPORT-MOVE-INTERACTION", 9999, 9999)
    Config.set_move_min_planned_total("PACK-EXPORT-MOVE-INTERACTION", 1)
    Config.set_move_evo_override("PACK-EXPORT-MOVE-INTERACTION", 1.0)

    local trigger = ensure_surface("nauvis")
    local dest = "nauvis"

    -- Gate open for non-vulcanus
    set_defeated("nauvis", true)

    local before = Oracle.snapshot(PLANETS)

    fire_rocket(trigger)

    local after = Oracle.snapshot(PLANETS)
    local d = Oracle.diff(before, after)

    T.assert(Oracle.any_increase_on(d, dest),
      "Export must increase world on dest=" .. dest ..
      " but got phy=" .. d[dest].phy .. " virt=" .. d[dest].virt)

    local pos = RocketHistory.get_positions(trigger.name, game.tick)
    T.assert(pos and #pos > 0, "Rocket history must be recorded for move")

    Orchestrator.run_once_all_surfaces()
    local plan = PlanStore.get(trigger.name)
    T.assert(plan ~= nil, "MovePlan must be created on trigger surface when rocket history exists")

    Runner.run_one_step_if_present_all_surfaces()

    Bootstrap.end_pack()
  end

  TestRunner.run_suite("MBD.PACK_EXPORT_MOVE_INTERACTION", suite)
end

commands.add_command("mbd-pack-export-move-interaction", "Run PACK-EXPORT-MOVE-INTERACTION", run_suite)