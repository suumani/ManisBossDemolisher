-- __ManisBossDemolisher__/scripts/services/demolisher_cap_service.lua
-- ----------------------------
-- 責務:
-- - 研究進行に応じた combat cap / fatal cap を計算する。
-- ----------------------------

local M = {}

local Calculator = require("__Manis_lib__/scripts/logic/DemolisherCapCalculator")

local POLICY = {
  GLOBAL_BASE_CAP = 200,
  FATAL_BASE_CAP = 200,

  REDUCTION_STEP = 0.05,

  GLOBAL_FLOOR = 10,
  FATAL_FLOOR = 10,

  TECH_NAME = "manis-demolisher-cap-down",
}

local function get_research_level(force)
  if not force or not force.technologies then
    return 0
  end

  local technology = force.technologies[POLICY.TECH_NAME]
  if not technology then
    return 0
  end

  return math.max(0, technology.level)
end

function M.get_combat_cap(force)
  local level = get_research_level(force)
  return Calculator.calculate(
    POLICY.GLOBAL_BASE_CAP,
    level,
    POLICY.REDUCTION_STEP,
    POLICY.GLOBAL_FLOOR
  )
end

function M.get_fatal_cap(force)
  local level = get_research_level(force)
  return Calculator.calculate(
    POLICY.FATAL_BASE_CAP,
    level,
    POLICY.REDUCTION_STEP,
    POLICY.FATAL_FLOOR
  )
end

return M