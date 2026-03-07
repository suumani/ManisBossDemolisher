-- __ManisBossDemolisher__/scripts/services/export_probability_service.lua
-- ----------------------------
-- 責務:
-- - 輸出成立確率を計算する。
-- - ロケット発射1回ごとの輸出成立判定を行う。
-- - 確率式は 0.25 + evo / 2 を適用する。
-- ----------------------------

local M = {}

local DeterministicRandom = require("scripts.util.deterministic_random")

local function clamp(value, min_value, max_value)
  if value < min_value then
    return min_value
  end
  if value > max_value then
    return max_value
  end
  return value
end

function M.get_probability(surface)
  local evo = game.forces.enemy.get_evolution_factor(surface)
  return clamp(0.25 + (evo / 2), 0, 1)
end

function M.should_spawn(surface)
  local probability = M.get_probability(surface)
  local roll = DeterministicRandom.random()
  return roll < probability
end

return M