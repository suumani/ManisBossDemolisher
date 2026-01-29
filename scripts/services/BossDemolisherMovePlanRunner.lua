-- __ManisBossDemolisher__/scripts/services/BossDemolisherMovePlanRunner.lua
local R = {}

local MovePlanStore = require("scripts.services.BossDemolisherMovePlanStore")
local Executor = require("scripts.services.BossDemolisherMoveExecutor")
local Logger = require("scripts.services.Logger")

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
  local count = 0
  
  for surface_name, plan in pairs(plans) do
    count = count + 1
    Logger.debug("[Runner] Checking plan for surface: " .. surface_name)

    if plan then
      if is_plan_expired(plan) then
          Logger.debug("  -> Plan EXPIRED. Clearing.")
          MovePlanStore.clear(surface_name)

      elseif is_plan_finished(plan) then
          Logger.debug(string.format(
            "  -> Plan FINISHED (Step:%d/%d, Moved:%d/%d). Clearing.",
            plan.step, (plan.rows * plan.cols),
            plan.moved_so_far, plan.planned_total
          ))
          MovePlanStore.clear(surface_name)

      else
          Logger.debug(string.format("  -> Executing Step... (Step: %d)", plan.step))
          
          -- Executor 実行
          Executor.execute_one_step(plan)
          
          if is_plan_finished(plan) then
             Logger.debug("    -> Plan Finished after execution. Clearing.")
             MovePlanStore.clear(surface_name)
          else
             MovePlanStore.set(surface_name, plan)
          end
      end

    else
        Logger.debug("  -> Plan is nil (Unexpected key in store?)")
    end
  end

  if count == 0 then
      Logger.debug("[Runner] No plans found in Store.")
  end
end

return R