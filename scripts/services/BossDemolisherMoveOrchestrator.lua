-- __ManisBossDemolisher__/scripts/services/BossDemolisherMoveOrchestrator.lua
-- Responsibility:
--   30分ごとに、各surfaceについて「移動計画（MovePlan）」を生成する。
--   対象選定は policy に委譲し、ここは結線と計画生成のみを担う。
local Orchestrator = {}

local RocketLaunchHistoryStore = require("__Manis_lib__/scripts/domain/demolisher/move/RocketLaunchHistoryStore")
local MovePlanner = require("__Manis_lib__/scripts/domain/demolisher/move/DemolisherMovePlanner")
local MovePlanStore = require("scripts.services.BossDemolisherMovePlanStore")
local MovePolicy = require("scripts.policies.boss_demolisher_move_policy")
local ModRandomProvider = require("scripts.services.ModRandomProvider")

local MAX_PLANNED_TOTAL = 100

function Orchestrator.run_once_all_surfaces()
  local rng = ModRandomProvider.get()

  for _, surface in pairs(game.surfaces) do
    if surface and surface.valid then
      local surface_name = surface.name

      -- TTL内ロケット履歴（Lib管理）
      local rocket_positions = RocketLaunchHistoryStore.get_positions(surface_name, game.tick)
      if rocket_positions and #rocket_positions > 0 then

        -- 対象は policy で決定
        local names = MovePolicy.get_target_names(surface_name)
        local demolishers = surface.find_entities_filtered{
          force = "enemy",
          name  = names
        }

        local count = #demolishers
        if count > 0 then
          local evo = game.forces.enemy.get_evolution_factor(surface)
          local planned_total = math.floor(count * evo * 0.5)
          if planned_total > MAX_PLANNED_TOTAL then planned_total = MAX_PLANNED_TOTAL end

          if planned_total > 0 then
            local plan = MovePlanner.build_plan(surface_name, planned_total, rocket_positions, rng)
            MovePlanStore.set(surface_name, plan)
          end
        end
      end
    end
  end
end

return Orchestrator