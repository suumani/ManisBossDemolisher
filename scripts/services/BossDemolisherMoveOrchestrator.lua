-- __ManisBossDemolisher__/scripts/services/BossDemolisherMoveOrchestrator.lua
local Orchestrator = {}

local RocketLaunchHistoryStore = require("__Manis_lib__/scripts/domain/demolisher/move/RocketLaunchHistoryStore")
local MovePlanner = require("__Manis_lib__/scripts/domain/demolisher/move/DemolisherMovePlanner")
local MovePlanStore = require("scripts.services.BossDemolisherMovePlanStore")
local MovePolicy = require("scripts.policies.boss_demolisher_move_policy")
local ModRandomProvider = require("scripts.services.ModRandomProvider")
local TestHooks = require("scripts.tests.infrastructure.TestHooks")

-- ★追加: 仮想マネージャ
local VirtualMgr = require("__Manis_lib__/scripts/managers/VirtualEntityManager")

local MAX_PLANNED_TOTAL = 100

function Orchestrator.run_once_all_surfaces()
  local rng = ModRandomProvider.get()

  for _, surface in pairs(game.surfaces) do
    if surface and surface.valid then
      local surface_name = surface.name

      local rocket_positions = RocketLaunchHistoryStore.get_positions(surface_name, game.tick)
      if rocket_positions and #rocket_positions > 0 then

        local names = MovePolicy.get_target_names(surface_name)
        
        -- 1. 実体のカウント (対象名フィルタ)
        local physical_count = surface.count_entities_filtered{
          force = "enemy",
          name  = names
        }

        -- 2. ★修正: 仮想のカウント (対象名フィルタ適用)
        -- MovePolicyで指定された対象のみをカウントし、計画の空回りを防ぐ
        local name_map = {}
        if names then
            for _, n in pairs(names) do name_map[n] = true end
        end

        local virtual_count = VirtualMgr.count(surface, function(entry)
            local d = entry.data
            if not d or not d.name then return false end
            return name_map[d.name] == true
        end)

        -- 合計数
        local count = physical_count + virtual_count

        if count > 0 then
          local evo = game.forces.enemy.get_evolution_factor(surface)
          -- 最低でも1匹は動くようにするか、evo依存にするかは調整次第
          -- ここでは元のロジックを尊重
          local planned_total = math.floor(count * evo * 0.5)
          
          -- Test hook: allow minimum planned_total in test mode (does not affect production).
          local min_pt = TestHooks.try_get_move_min_planned_total()
          if type(min_pt) == "number" and min_pt > 0 and planned_total < min_pt then
            planned_total = min_pt
          end

          if planned_total > MAX_PLANNED_TOTAL then planned_total = MAX_PLANNED_TOTAL end

          -- テスト時はevoが低くて0になりがちなので、デバッグ用に最低保証を入れるのもありですが、
          -- 本番バランスに関わるのでここではそのままにします。
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