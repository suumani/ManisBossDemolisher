-- __ManisBossDemolisher__/scripts/events/on_nth_tick_30min.lua
-- ----------------------------
-- 30分ごとのCombatデモリッシャー移動
-- ----------------------------

local Orchestrator = require("scripts.services.BossDemolisherMoveOrchestrator")
local nest_spawner = require("scripts.services.demolisher_nest_spawner")

local TICKS_30_MIN = 60 * 60 * 30

script.on_nth_tick(TICKS_30_MIN, function()
  -- 30分：計画作成（各surface）
  Orchestrator.run_once_all_surfaces()

  -- 既存の巣スポーンは維持（nauvis/gleba）
  local nauvis = game.surfaces["nauvis"]
  if nauvis and nauvis.valid then nest_spawner.spawn_nauvis(nauvis) end

  local gleba = game.surfaces["gleba"]
  if gleba and gleba.valid then nest_spawner.spawn_gleba(gleba) end

  -- 警告メッセージリセット
  storage.manis_export_message_suppressed = nil
end)