-- __ManisBossDemolisher__/scripts/services/BossDemolisherMoveExecutor.lua
-- Responsibility:
--   Libの共通実行器に対して、BossMod固有の「対象抽選（policy）」と「乱数注入」を結線する。
local E = {}

local StepExecutor = require("__Manis_lib__/scripts/domain/demolisher/move/DemolisherMoveStepExecutor")
local MovePolicy   = require("scripts.policies.boss_demolisher_move_policy")
local ModRandomProvider = require("scripts.services.ModRandomProvider")

local function get_rocket_positions(plan)
  return plan.rocket_positions or plan.positions
end

-- BossMod固有：対象抽選は policy に委譲
local function build_move_targets(surface, area, ctx)
  local names = MovePolicy.get_target_names(surface.name)
  return surface.find_entities_filtered{
    force = "enemy",
    name  = names,
    area  = area
  } or {}
end

function E.execute_one_step(plan)
  return StepExecutor.execute_one_step(plan, {
    get_surface = function(surface_name) return game.surfaces[surface_name] end,
    get_rocket_positions = get_rocket_positions,
    build_move_targets = build_move_targets,
    compute_move_rate = MovePolicy.compute_move_rate,
    can_move = MovePolicy.can_move,
    get_rng = function() return ModRandomProvider.get() end,
    mod_name = "ManisBossDemolisher",
    log = log,
  })
end

return E