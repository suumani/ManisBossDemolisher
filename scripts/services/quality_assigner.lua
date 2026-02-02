-- __ManisBossDemolisher__/scripts/services/quality_assigner.lua
-- ----------------------------
-- Quality assigner
-- ----------------------------
local Q = {}

local DRand = require("scripts.util.DeterministicRandom")
local QualityRoller = require("__Manis_lib__/scripts/rollers/QualityRoller")
local TestHooks = require("scripts.tests.infrastructure.TestHooks")

-- Responsibility:
-- Decide entity quality on spawn.
-- Rule: first time per (surface, name) => "normal", otherwise random.
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

  local r = TestHooks.try_get_export_quality_roll_override()
  if type(r) ~= "number" then
    r = DRand.random()
  end
  return QualityRoller.choose_quality(opts.dest_evo, r)
end

return Q