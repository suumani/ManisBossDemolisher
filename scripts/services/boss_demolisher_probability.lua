-- __ManisBossDemolisher__/scripts/services/boss_demolisher_probability.lua
local P = {}

local DRand = require("scripts.util.DeterministicRandom")

local function clamp(x, lo, hi)
	if x < lo then return lo end
	if x > hi then return hi end
	return x
end

local CONFIG = {
  export = {
    p_base = 0.25,   -- 仮。トリガ増えたので低めから
    p_min  = 0.02,
    p_max  = 0.60,
  }
}

-- export は確率で抑止しない（上限は spawner 側 cap が担保）
function P.should_spawn(surface, ctx, kind)
  return kind == "export"
end

return P