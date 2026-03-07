-- __ManisBossDemolisher__/scripts/services/destination_surface_selector.lua
-- ----------------------------
-- 責務:
-- - 輸出先 surface を選定する。
-- - 輸出元 surface は候補から除外する。
-- - 既知の対象惑星から存在するもののみを候補にする。
-- ----------------------------

local M = {}

local DeterministicRandom = require("scripts.util.deterministic_random")

local CANDIDATE_SURFACE_NAMES = {
  "nauvis",
  "vulcanus",
  "gleba",
  "fulgora",
  "aquilo",
}

function M.choose_destination_surface(ctx)
  local trigger_surface = ctx and ctx.trigger_surface
  local trigger_surface_name = (trigger_surface and trigger_surface.valid) and trigger_surface.name or nil

  local candidates = {}

  for _, surface_name in ipairs(CANDIDATE_SURFACE_NAMES) do
    if surface_name ~= trigger_surface_name then
      local surface = game.surfaces[surface_name]
      if surface and surface.valid then
        table.insert(candidates, surface)
      end
    end
  end

  if #candidates == 0 then
    return nil
  end

  return candidates[DeterministicRandom.random(1, #candidates)]
end

return M