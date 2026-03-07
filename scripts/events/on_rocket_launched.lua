-- __ManisBossDemolisher__/scripts/events/on_rocket_launched.lua
-- ----------------------------
-- 責務:
-- - ロケット発射イベントを受け取り、輸出トリガ処理を起動する。
-- - defeated gate を判定し、条件を満たす場合のみ control へ委譲する。
-- ----------------------------

local boss_demolisher_control = require("scripts.control.boss_demolisher_control")
local Logger = require("scripts.services.Logger")

local function handle(event)
  local silo = event.rocket_silo
  if not silo or not silo.valid then
    return
  end

  local surface = silo.surface
  if not surface or not surface.valid then
    return
  end

  local defeated =
    storage.manis_boss_demolisher_flag
    and storage.manis_boss_demolisher_flag[surface.name]
    and storage.manis_boss_demolisher_flag[surface.name].defeated == true

  Logger.info({
    "[Rocket][Launched]",
    " trigger_surface=", surface.name,
    " silo_pos={", silo.position.x, ",", silo.position.y, "}",
    " tick=", event.tick,
    " defeated=", defeated == true and "true" or "false",
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

  boss_demolisher_control.on_rocket_launched_export({
    trigger_surface = surface,
    silo = silo,
  })
end

script.on_event(defines.events.on_rocket_launched, handle)

return { handle = handle }