-- __ManisBossDemolisher__/scripts/policies/boss_demolisher_move_policy.lua
local Policy = {}

local EntityNames = require("scripts.defines.EntityNames")

-- 惑星別の移動対象
function Policy.get_target_names(surface_name)
  if surface_name == "vulcanus" or surface_name == "fulgora" then
    return EntityNames.ALL_BOSS_DEMOLISHERS
  end
  return EntityNames.ALL_COMBAT_DEMOLISHERS
end

-- 進化度による移動可否（BossMod固有）
local thresholds = {
  [EntityNames.small_demolisher] = 0.4,
  [EntityNames.medium_demolisher] = 0.7,
  [EntityNames.big_demolisher] = 0.9,

  [EntityNames.manis_behemoth_demolisher] = 0.95,
  [EntityNames.manis_speedstar_small_demolisher] = 0.85,
  [EntityNames.manis_speedstar_medium_demolisher] = 0.90,
  [EntityNames.manis_speedstar_big_demolisher] = 0.95,
  [EntityNames.manis_speedstar_behemoth_demolisher] = 0.99,
}

function Policy.can_move(name, evo)
  local t = thresholds[name]
  return t ~= nil and evo > t
end

function Policy.compute_move_rate(rocket_positions)
  local n = rocket_positions and #rocket_positions or 0
  if n > 3 then n = 3 end
  return n
end

return Policy