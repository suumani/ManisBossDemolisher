-- __ManisBossDemolisher__/scripts/services/demolisher_quality_service.lua
-- ----------------------------
-- 責務:
-- - 輸出個体の quality を決定する。
-- - 初回出現は normal 固定とする。
-- - 2回目以降は evo 基準の QualityRoller を使用する。
-- ----------------------------

local M = {}

local QualityRoller = require("__Manis_lib__/scripts/rollers/QualityRoller")
local DeterministicRandom = require("scripts.util.deterministic_random")
local BossDemolisherFlagStore = require("scripts.stores.boss_demolisher_flag_store")

function M.choose(surface, opts)
  opts = opts or {}

  local entity_name = opts.entity_name
  if not surface or not surface.valid or not entity_name then
    return "normal"
  end

  if not BossDemolisherFlagStore.has_spawned(surface.name, entity_name) then
    return "normal"
  end

  local roll = DeterministicRandom.random()
  return QualityRoller.choose_quality(opts.dest_evo, roll)
end

return M