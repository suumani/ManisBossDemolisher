-- scripts/services/boss_demolisher_probability.lua
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

function P.should_spawn(surface, ctx, kind)
	if kind ~= "export" then return false end

	local trigger_surface = ctx.trigger_surface
	local sname = trigger_surface.name

	-- 1) 討伐前は発動しない
	local killed = storage.manis_demolisher_killed_surface
		and storage.manis_demolisher_killed_surface[sname] == true
	if not killed then
		return false
	end

	-- 2) 討伐後の1発目は100%
	storage.manis_export_guaranteed_used = storage.manis_export_guaranteed_used or {}
	if storage.manis_export_guaranteed_used[sname] ~= true then
		return true
	end

	-- 3) 以降は通常確率（evo補正のみ）
	local evo = game.forces.enemy.get_evolution_factor(trigger_surface)
	local p = CONFIG.export.p_base * (0.2 + evo / 2)
	p = clamp(p, CONFIG.export.p_min, CONFIG.export.p_max)
	return DRand.random() < p
end

return P