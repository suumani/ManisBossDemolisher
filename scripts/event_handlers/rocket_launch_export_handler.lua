-- __ManisBossDemolisher__/scripts/event_handlers/rocket_launch_export_handler.lua
-- ----------------------------
-- 責務:
-- - ロケット発射イベントを受ける。
-- - defeated gate を判定する。
-- - イベント境界でのみ pcall により異常を捕捉する。
-- - 条件を満たす場合のみ RocketExportUseCase へ委譲する。
-- ----------------------------

local M = {}

local Logger = require("scripts.logging.logger")
local BossDemolisherFlagStore = require("scripts.stores.boss_demolisher_flag_store")
local RocketExportUseCase = require("scripts.use_cases.rocket_export_use_case")

local function execute_guarded(event, silo, surface)
  local defeated = BossDemolisherFlagStore.is_defeated(surface.name)

  Logger.info({
    "[Rocket][Launched]",
    " trigger_surface=", surface.name,
    " silo_pos={", silo.position.x, ",", silo.position.y, "}",
    " tick=", event.tick,
    " defeated=", defeated and "true" or "false",
  })

  if surface.name ~= "vulcanus" and not defeated then
    Logger.info({
      "[Export][Skip]",
      " reason=defeated_gate",
      " trigger_surface=", surface.name,
      " tick=", event.tick,
    })
    return
  end

  RocketExportUseCase.execute({
    trigger_surface = surface,
    silo = silo,
    tick = event.tick,
  })
end

function M.handle(event)
  local silo = event and event.rocket_silo
  if not silo or not silo.valid then
    return
  end

  local surface = silo.surface
  if not surface or not surface.valid then
    return
  end

  local ok, err = pcall(execute_guarded, event, silo, surface)
  if ok then
    return
  end

  Logger.error({
    "[Rocket][Handler][Fail]",
    " trigger_surface=", surface.name,
    " silo_pos={", silo.position.x, ",", silo.position.y, "}",
    " tick=", event.tick,
    " error=", tostring(err),
  })
end

return M