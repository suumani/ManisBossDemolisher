-- scripts/tests/packs/move/PackMoveSchedule.lua
-- ------------------------------------------------------------
-- Responsibility:
--   PACK-MOVE-SCHEDULE:
--   - MOVE-SCH-001: plan creation + step advance
--   - MOVE-SCH-002: combat moves, fatal does not
--   - MOVE-SCH-003A..003D: move distance constraint for each transition type:
--       003A Phys->Phy
--       003B Phys->Vir
--       003C Vir ->Phy
--       003D Vir ->Vir
--
-- Notes:
--   - TestBootstrap does NOT clear the whole world; each scenario cleans up physical entities.
--   - clear_virtual=true clears storage.virtual_entities + storage.virtual_id_seq (confirmed).
--   - Distance constraint is validated per SINGLE move delta (not cumulative).
-- ------------------------------------------------------------
-- Test Results:
-- ver.0.1.6 Passed
-- ------------------------------------------------------------
local TestRunner = require("__Manis_TestFramework__/scripts/test/TestRunner")

local Bootstrap = require("scripts.tests.infrastructure.TestBootstrap")
local Config    = require("scripts.tests.infrastructure.TestConfig")

local RocketHistory = require("__Manis_lib__/scripts/domain/demolisher/move/RocketLaunchHistoryStore")
local Orchestrator  = require("scripts.services.BossDemolisherMoveOrchestrator")
local Runner        = require("scripts.services.BossDemolisherMovePlanRunner")
local PlanStore     = require("scripts.services.BossDemolisherMovePlanStore")

local VirtualMgr    = require("__Manis_lib__/scripts/managers/VirtualEntityManager")
local DemolisherNames = require("__Manis_definitions__/scripts/definition/DemolisherNames")
local MovePolicy      = require("scripts.policies.boss_demolisher_move_policy")

local PLANETS = { "nauvis", "gleba", "fulgora", "vulcanus", "aquilo" }

-- ----------------------------
-- helpers
-- ----------------------------
local function ensure_surface(name)
  local s = game.surfaces[name]
  if s then return s end
  return game.create_surface(name, {})
end

local function create_unique_surface(prefix)
  storage = storage or {}
  storage._test_surface_seq = (storage._test_surface_seq or 0) + 1
  local name = string.format("%s_%d_%d", prefix, game.tick, storage._test_surface_seq)
  return game.create_surface(name, {})
end

local function ensure_chunks_generated(surface, center_pos, radius)
  surface.request_to_generate_chunks(center_pos, radius)
  surface.force_generate_chunk_requests()
end

local function destroy_all_by_names(surface, names)
  if not names then return end
  local ents = surface.find_entities_filtered{
    force = "enemy",
    name  = names
  }
  for _, e in pairs(ents) do
    if e and e.valid then e.destroy() end
  end
end

local function destroy_all_by_name(surface, name)
  local ents = surface.find_entities_filtered{ force = "enemy", name = name }
  for _, e in pairs(ents) do
    if e and e.valid then e.destroy() end
  end
end

local function cleanup_surface_for_move_tests(surface, surface_name)
  -- Clear plans (Bootstrap doesn't clear MovePlanStore)
  if surface_name then
    PlanStore.clear(surface_name)
  end

  -- Remove all MOVE targets (combat/boss targets depending on planet policy).
  local targets = MovePolicy.get_target_names(surface.name)
  destroy_all_by_names(surface, targets)

  -- Also remove fatal we may spawn in this pack.
  destroy_all_by_name(surface, DemolisherNames.MANIS_GIGANTIC_SMALL)
end

local function spawn_one_demolisher(surface, name, pos)
  surface.create_entity{ name = name, position = pos, force = "enemy", quality = "normal" }
end

local function find_one(surface, name)
  local ents = surface.find_entities_filtered{ force = "enemy", name = name }
  for _, e in pairs(ents) do
    if e and e.valid then return e end
  end
  return nil
end

local function count_physical(surface, name)
  local ents = surface.find_entities_filtered{ force="enemy", name=name }
  local c = 0
  for _, e in pairs(ents) do
    if e and e.valid then c = c + 1 end
  end
  return c
end

local function euclid_dist(a, b)
  local dx = a.x - b.x
  local dy = a.y - b.y
  return math.sqrt(dx * dx + dy * dy)
end

local function add_rockets(surface_name, list)
  for _, p in ipairs(list) do
    RocketHistory.add(surface_name, p, game.tick)
  end
end

local function make_virtual_data(name)
  -- BossDemolisherMoveExecutor.create_adapter(virt) expects:
  -- d.name, d.force, d.quality (string or userdata)
  return {
    name = name,
    force = "enemy",
    quality = "normal",
  }
end

local function get_virtual_entry_by_id(surface, vid)
  return VirtualMgr.get(surface, vid)
end

local function count_virtual_by_name(surface, name)
  local list = VirtualMgr.get_all_as_list(surface)
  local c = 0
  for _, entry in pairs(list) do
    if entry and entry.data and entry.data.name == name then
      c = c + 1
    end
  end
  return c
end

-- Common maxd calculation (As-Is in DemolisherMover):
-- maxd = floor(30 * evo * move_rate) + 30
local function calc_maxd(evo, move_rate)
  return math.floor(30 * evo * move_rate) + 30
end

-- Run runner until:
-- - plan is cleared OR
-- - step limit reached
local function run_steps_until_done(surface_name, max_steps)
  max_steps = max_steps or 40
  for _ = 1, max_steps do
    if not PlanStore.get(surface_name) then return end
    Runner.run_one_step_if_present_all_surfaces()
  end
end

-- ----------------------------
-- suite
-- ----------------------------
local function run_suite()
  local suite = {}

  suite["MOVE-SCH-001: plan is created and step advances when prerequisites are satisfied"] = function(T)
    Bootstrap.start_pack("PACK-MOVE-SCHEDULE", {
      clear_virtual = true,
      clear_mbd_transients = true,
    })

    Config.set_move_min_planned_total("PACK-MOVE-SCHEDULE", 1)
    Config.set_move_evo_override("PACK-MOVE-SCHEDULE", 1.0)

    for _, n in ipairs(PLANETS) do ensure_surface(n) end
    local s = ensure_surface("nauvis")

    cleanup_surface_for_move_tests(s, "nauvis")

    RocketHistory.add("nauvis", {x=0,y=0}, game.tick)
    spawn_one_demolisher(s, DemolisherNames.MANIS_SMALL, {x=100, y=0})

    Orchestrator.run_once_all_surfaces()

    local plan = PlanStore.get("nauvis")
    T.assert(plan ~= nil, "Plan must be created on nauvis when rocket history and targets exist (min planned_total hook).")

    local before_step = plan.step
    local before_moved = plan.moved_so_far

    Runner.run_one_step_if_present_all_surfaces()

    local plan2 = PlanStore.get("nauvis")
    if plan2 then
      T.assert(plan2.step == before_step + 1, "Plan step must advance by 1 after runner step.")
      T.assert(plan2.moved_so_far >= before_moved, "moved_so_far must not decrease.")
    else
      T.assert(true, "Plan finished and cleared after one step (allowed).")
    end

    Bootstrap.end_pack()
  end

  suite["MOVE-SCH-002: combat moves but fatal does not move (within N steps)"] = function(T)
    Bootstrap.start_pack("PACK-MOVE-SCHEDULE", {
      clear_virtual = true,
      clear_mbd_transients = true,
    })

    Config.set_move_min_planned_total("PACK-MOVE-SCHEDULE", 1)
    Config.set_move_evo_override("PACK-MOVE-SCHEDULE", 1.0)

    local surface = ensure_surface("nauvis")
    cleanup_surface_for_move_tests(surface, "nauvis")

    RocketHistory.add("nauvis", {x=0,y=0}, game.tick)

    local combat_name = DemolisherNames.MANIS_SMALL
    local fatal_name  = DemolisherNames.MANIS_GIGANTIC_SMALL

    local combat_start = { x = 100,  y = 0 }
    local fatal_start  = { x = 2100, y = 0 }

    surface.create_entity{ name = combat_name, position = combat_start, force="enemy", quality="normal" }
    surface.create_entity{ name = fatal_name,  position = fatal_start,  force="enemy", quality="normal" }

    local before_combat = find_one(surface, combat_name)
    local before_fatal  = find_one(surface, fatal_name)
    T.assert(before_combat ~= nil, "combat entity must exist")
    T.assert(before_fatal ~= nil, "fatal entity must exist")

    local before_combat_pos = { x = before_combat.position.x, y = before_combat.position.y }
    local before_fatal_pos  = { x = before_fatal.position.x,  y = before_fatal.position.y }

    Orchestrator.run_once_all_surfaces()

    local N = 30
    local combat_moved = false
    for _ = 1, N do
      Runner.run_one_step_if_present_all_surfaces()
      local cur = find_one(surface, combat_name)
      if cur then
        if cur.position.x ~= before_combat_pos.x or cur.position.y ~= before_combat_pos.y then
          combat_moved = true
          break
        end
      else
        combat_moved = true
        break
      end
    end

    local cur_fatal = find_one(surface, fatal_name)
    T.assert(cur_fatal ~= nil, "fatal entity must remain physical (not targeted)")
    local fatal_moved =
      cur_fatal.position.x ~= before_fatal_pos.x or
      cur_fatal.position.y ~= before_fatal_pos.y

    T.assert(combat_moved, "Combat demolisher must move within N steps under test evo override.")
    T.assert(not fatal_moved, "Fatal demolisher must not move.")

    Bootstrap.end_pack()
  end

  -- ------------------------------------------------------------
  -- MOVE-SCH-003A: Phys -> Phy
  -- ------------------------------------------------------------
suite["MOVE-SCH-003A: distance constraint (Phys->Phy)"] = function(T)
  Bootstrap.start_pack("PACK-MOVE-SCHEDULE", {
    clear_virtual = true,
    clear_mbd_transients = true,
  })

  Config.set_move_min_planned_total("PACK-MOVE-SCHEDULE", 1)
  Config.set_move_evo_override("PACK-MOVE-SCHEDULE", 1.0)

  local surface_name = "nauvis"
  local surface = ensure_surface(surface_name)
  cleanup_surface_for_move_tests(surface, surface_name)

  -- ----------------------------------------------------------------
  -- Force Phys->Phy by:
  --   - placing rockets near origin (generated)
  --   - placing demolisher near rockets (generated)
  --   => move_pos stays inside generated area with high probability
  -- ----------------------------------------------------------------
  local rockets = { {x=0,y=0}, {x=10,y=0}, {x=0,y=10} }
  for _, p in ipairs(rockets) do
    ensure_chunks_generated(surface, p, 12)
  end
  add_rockets(surface_name, rockets)

  local name = DemolisherNames.MANIS_SMALL
  local start_pos = { x = 40, y = 0 }
  ensure_chunks_generated(surface, start_pos, 12)
  spawn_one_demolisher(surface, name, start_pos)

  Orchestrator.run_once_all_surfaces()
  T.assert(PlanStore.get(surface_name) ~= nil, "Plan must exist for Phys->Phy test.")

  local evo = 1.0
  local move_rate = 3
  local maxd = calc_maxd(evo, move_rate)
  local epsilon = 0.51

  local moved_observed = false

  for _ = 1, 40 do
    if not PlanStore.get(surface_name) then break end

    local before = find_one(surface, name)
    T.assert(before ~= nil, "Physical entity must exist before move (Phys->Phy).")
    local bp = { x = before.position.x, y = before.position.y }

    Runner.run_one_step_if_present_all_surfaces()

    local after = find_one(surface, name)
    if not after then
      -- If it became virtual, precondition was violated (still useful info).
      local vcount = count_virtual_by_name(surface, name)
      T.assert(vcount == 0, "Phys->Phy precondition violated: entity became virtual (Phy->Vir).")
      T.assert(false, "Phys->Phy: physical entity disappeared unexpectedly.")
    end

    local ap = { x = after.position.x, y = after.position.y }
    local dist = euclid_dist(bp, ap)

    if dist > 0.1 then
      moved_observed = true
      T.assert(dist <= (maxd + epsilon),
        string.format("Phys->Phy delta must be <= maxd. dist=%.3f maxd=%d", dist, maxd))
      break
    end
  end

  T.assert(moved_observed, "A measurable Phys->Phy move must be observed within plan lifetime.")
  Bootstrap.end_pack()
end

  -- ------------------------------------------------------------
  -- MOVE-SCH-003B: Phys -> Vir
  --   Force virtualization by generating ONLY the spawn chunk,
  --   and pushing movement toward ungenerated neighbor chunks.
  -- ------------------------------------------------------------
suite["MOVE-SCH-003B: distance constraint (Phys->Vir)"] = function(T)
  Bootstrap.start_pack("PACK-MOVE-SCHEDULE", {
    clear_virtual = true,
    clear_mbd_transients = true,
  })

  Config.set_move_min_planned_total("PACK-MOVE-SCHEDULE", 1)
  Config.set_move_evo_override("PACK-MOVE-SCHEDULE", 1.0)

  local surface = create_unique_surface("mbd_test_003b")
  local surface_name = surface.name

  cleanup_surface_for_move_tests(surface, surface_name)

  -- Only generate the spawn chunk.
  local start_pos = { x = 31, y = 0 }
  ensure_chunks_generated(surface, start_pos, 0)

  -- Rockets far to +x, do NOT generate around them.
  add_rockets(surface_name, {
    {x=1000,y=0},{x=1000,y=50},{x=1000,y=-50}
  })

  local name = DemolisherNames.MANIS_SMALL
  spawn_one_demolisher(surface, name, start_pos)

  local evo = 1.0
  local move_rate = 3
  local maxd = calc_maxd(evo, move_rate)
  local epsilon = 0.51

  local transitioned = false
  local delta_checked = false

  local K = 6
  for _ = 1, K do
    if transitioned and delta_checked then break end

    PlanStore.clear(surface_name)
    Orchestrator.run_once_all_surfaces()

    local plan = PlanStore.get(surface_name)
    if plan then
      for _ = 1, 25 do
        if transitioned and delta_checked then break end
        if not PlanStore.get(surface_name) then break end

        local before = find_one(surface, name)
        if before then
          local bp = { x = before.position.x, y = before.position.y }

          Runner.run_one_step_if_present_all_surfaces()

          local after = find_one(surface, name)
          if not after then
            local list = VirtualMgr.get_all_as_list(surface)
            local found = nil
            for _, entry in pairs(list) do
              if entry and entry.data and entry.data.name == name then
                found = entry
                break
              end
            end

            if found then
              transitioned = true
              local vp = { x = found.position.x, y = found.position.y }

              local dist = euclid_dist(bp, vp)
              T.assert(dist <= (maxd + epsilon),
                string.format("Phys->Vir delta must be <= maxd. dist=%.3f maxd=%d", dist, maxd))

              delta_checked = true
              break
            end
          end
        else
          -- already virtual; keep stepping within this plan
          Runner.run_one_step_if_present_all_surfaces()
        end
      end
    end
  end

  T.assert(transitioned and delta_checked, "Phys->Vir transition and delta check must occur within retries (K plans).")
  Bootstrap.end_pack()
end

  -- ------------------------------------------------------------
  -- MOVE-SCH-003C: Vir -> Phy
  --   Start as virtual, move into generated area to materialize.
  -- ------------------------------------------------------------
suite["MOVE-SCH-003C: distance constraint (Vir->Phy)"] = function(T)
  Bootstrap.start_pack("PACK-MOVE-SCHEDULE", {
    clear_virtual = true,
    clear_mbd_transients = true,
  })

  Config.set_move_min_planned_total("PACK-MOVE-SCHEDULE", 1)
  Config.set_move_evo_override("PACK-MOVE-SCHEDULE", 1.0)

  local surface_name = "nauvis"
  local surface = ensure_surface(surface_name)
  cleanup_surface_for_move_tests(surface, surface_name)

  local name = DemolisherNames.MANIS_SMALL

  local rockets = { {x=0,y=0}, {x=10,y=0}, {x=0,y=10} }
  for _, p in ipairs(rockets) do
    ensure_chunks_generated(surface, p, 12)
  end
  add_rockets(surface_name, rockets)

  local vpos = { x = 40, y = 0 }
  ensure_chunks_generated(surface, vpos, 12)

  local vid = VirtualMgr.enqueue(surface, nil, vpos, make_virtual_data(name))
  T.assert(vid ~= nil, "Virtual id must be returned for Vir->Phy test.")

  local evo = 1.0
  local move_rate = 3
  local maxd = calc_maxd(evo, move_rate)
  local epsilon = 0.51

  local transitioned = false
  local delta_checked = false

  local K = 5
  for _ = 1, K do
    if transitioned and delta_checked then break end

    PlanStore.clear(surface_name)
    Orchestrator.run_once_all_surfaces()

    local plan = PlanStore.get(surface_name)
    if plan then
      for _ = 1, 25 do
        if transitioned and delta_checked then break end
        if not PlanStore.get(surface_name) then break end

        local before_entry = VirtualMgr.get(surface, vid)
        if before_entry then
          local bp = { x = before_entry.position.x, y = before_entry.position.y }

          Runner.run_one_step_if_present_all_surfaces()

          local after_entry = VirtualMgr.get(surface, vid)
          local after_phys = find_one(surface, name)

          if (not after_entry) and after_phys then
            transitioned = true

            local ap = { x = after_phys.position.x, y = after_phys.position.y }
            local dist = euclid_dist(bp, ap)

            T.assert(dist <= (maxd + epsilon),
              string.format("Vir->Phy delta must be <= maxd. dist=%.3f maxd=%d", dist, maxd))

            delta_checked = true
            break
          end
        else
          Runner.run_one_step_if_present_all_surfaces()
        end
      end
    end
  end

  T.assert(transitioned and delta_checked, "Vir->Phy transition and delta check must occur within retries (K plans).")
  Bootstrap.end_pack()
end

  -- ------------------------------------------------------------
  -- MOVE-SCH-003D: Vir -> Vir
  --   Start as virtual, ensure target_pos stays ungenerated so it remains virtual.
  -- ------------------------------------------------------------
suite["MOVE-SCH-003D: distance constraint (Vir->Vir)"] = function(T)
  Bootstrap.start_pack("PACK-MOVE-SCHEDULE", {
    clear_virtual = true,
    clear_mbd_transients = true,
  })

  Config.set_move_min_planned_total("PACK-MOVE-SCHEDULE", 1)
  Config.set_move_evo_override("PACK-MOVE-SCHEDULE", 1.0)

  local surface = create_unique_surface("mbd_test_003d")
  local surface_name = surface.name

  cleanup_surface_for_move_tests(surface, surface_name)

  -- Only generate the starting chunk.
  local vpos = { x = 31, y = 0 }
  ensure_chunks_generated(surface, vpos, 0)

  add_rockets(surface_name, {
    {x=1000,y=0},{x=1000,y=50},{x=1000,y=-50}
  })

  local name = DemolisherNames.MANIS_SMALL
  local vid = VirtualMgr.enqueue(surface, nil, vpos, make_virtual_data(name))
  T.assert(vid ~= nil, "Virtual id must be returned for Vir->Vir test.")

  local evo = 1.0
  local move_rate = 3
  local maxd = calc_maxd(evo, move_rate)
  local epsilon = 0.51

  local moved_observed = false
  local delta_checked = false

  local K = 6
  for _ = 1, K do
    if moved_observed and delta_checked then break end

    PlanStore.clear(surface_name)
    Orchestrator.run_once_all_surfaces()

    local plan = PlanStore.get(surface_name)
    if plan then
      for _ = 1, 25 do
        if moved_observed and delta_checked then break end
        if not PlanStore.get(surface_name) then break end

        local before_entry = VirtualMgr.get(surface, vid)
        T.assert(before_entry ~= nil, "Vir->Vir: virtual entry must exist before move.")

        local bp = { x = before_entry.position.x, y = before_entry.position.y }

        Runner.run_one_step_if_present_all_surfaces()

        local after_entry = VirtualMgr.get(surface, vid)
        T.assert(after_entry ~= nil, "Vir->Vir: virtual entry disappeared unexpectedly (materialized/removed).")

        local ap = { x = after_entry.position.x, y = after_entry.position.y }
        local dist = euclid_dist(bp, ap)

        if dist > 0.1 then
          moved_observed = true
          T.assert(count_physical(surface, name) == 0, "Vir->Vir must not materialize to physical.")
          T.assert(dist <= (maxd + epsilon),
            string.format("Vir->Vir delta must be <= maxd. dist=%.3f maxd=%d", dist, maxd))
          delta_checked = true
          break
        end
      end
    end
  end

  T.assert(moved_observed and delta_checked, "A measurable Vir->Vir move must be observed within retries (K plans).")
  Bootstrap.end_pack()
end
  TestRunner.run_suite("MBD.PACK_MOVE_SCHEDULE", suite)
end


commands.add_command("mbd-pack-move-schedule", "Run PACK-MOVE-SCHEDULE", run_suite)