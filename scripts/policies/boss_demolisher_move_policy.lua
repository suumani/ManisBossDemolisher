-- __ManisBossDemolisher__/scripts/policies/boss_demolisher_move_policy.lua
local Policy = {}

local DemolisherNames = require("__Manis_definitions__/scripts/definition/DemolisherNames")

-- 惑星別の移動対象
function Policy.get_target_names(surface_name)
  if surface_name == "vulcanus" or surface_name == "fulgora" then
    return DemolisherNames.ALL_BOSS
  end
  return DemolisherNames.ALL_COMBAT
end

-- 進化度による移動可否（BossMod固有）
local thresholds = {
  [DemolisherNames.SMALL] = 0.05,
  [DemolisherNames.MANIS_SMALL] = 0.05,
  [DemolisherNames.MANIS_SMALL_ALT] = 0.05,

  [DemolisherNames.MEDIUM] = 0.2,
  [DemolisherNames.MANIS_MEDIUM] = 0.2,
  [DemolisherNames.MANIS_MEDIUM_ALT] = 0.2,

  [DemolisherNames.BIG] = 0.4,
  [DemolisherNames.MANIS_BIG] = 0.4,
  [DemolisherNames.MANIS_BIG_ALT] = 0.4,

  [DemolisherNames.MANIS_BEHEMOTH] = 0.6,
  [DemolisherNames.MANIS_BEHEMOTH_ALT] = 0.6,

  [DemolisherNames.MANIS_SPEEDSTAR_SMALL] = 0.25,
  [DemolisherNames.MANIS_SPEEDSTAR_SMALL_ALT] = 0.25,

  [DemolisherNames.MANIS_SPEEDSTAR_MEDIUM] = 0.45,
  [DemolisherNames.MANIS_SPEEDSTAR_MEDIUM_ALT] = 0.45,

  [DemolisherNames.MANIS_SPEEDSTAR_BIG] = 0.65,
  [DemolisherNames.MANIS_SPEEDSTAR_BIG_ALT] = 0.65,

  [DemolisherNames.MANIS_SPEEDSTAR_BEHEMOTH] = 0.85,
  [DemolisherNames.MANIS_SPEEDSTAR_BEHEMOTH_ALT] = 0.85,
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