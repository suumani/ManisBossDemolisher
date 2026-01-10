-- __ManisBossDemolisher__/scripts/services/BossDemolisherMovePlanRunner.lua
local R = {}

local MovePlanStore = require("scripts.services.BossDemolisherMovePlanStore")
local Executor = require("scripts.services.BossDemolisherMoveExecutor")

local MAX_PLAN_AGE_TICKS = 60 * 60 * 60

local function is_plan_expired(plan)
  return plan.created_tick and (game.tick - plan.created_tick) > MAX_PLAN_AGE_TICKS
end

local function is_plan_finished(plan)
  local cell_count = plan.rows * plan.cols
  return (plan.moved_so_far >= plan.planned_total) or (plan.step > cell_count)
end

function R.run_one_step_if_present_all_surfaces()
  local plans = MovePlanStore.get_all()
  for surface_name, plan in pairs(plans) do
    if plan then
      if is_plan_expired(plan) or is_plan_finished(plan) then
        MovePlanStore.clear(surface_name)
      else
        Executor.execute_one_step(plan)
        if is_plan_finished(plan) then
          MovePlanStore.clear(surface_name)
        else
          MovePlanStore.set(surface_name, plan)
        end
      end
    end
  end
end

return R