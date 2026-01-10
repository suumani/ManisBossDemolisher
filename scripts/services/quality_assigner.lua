-- ----------------------------
-- Quality assigner
-- scripts/services/quality_assigner.lua
-- ----------------------------
local Q = {}

local QualityNames = require("__Manis_lib__/scripts/definition/QualityNames")
local DRand = require("scripts.util.DeterministicRandom")
local QualityRoller = require("__Manis_lib__/scripts/rollers/QualityRoller")

-- Responsibility:
-- Decide entity quality on spawn.
-- Rule: first time per (surface, entity_name) => "normal", otherwise random.
function Q.choose(surface, opts)
  opts = opts or {}
  local entity_name = opts.entity_name
  if not surface or not surface.valid or not entity_name then
    return "normal"
  end

  local flags = storage.manis_boss_demolisher_flag
  local per_surface = flags and flags[surface.name]
  local seen = per_surface and (per_surface[entity_name] == true)

  if not seen then
    return "normal"
  end
  return QualityRoller.choose_quality(opts.source_evo, DRand.random())
end

return Q