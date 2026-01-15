-- __ManisBossDemolisher__/scripts/control/boss_demolisher_control.lua
-- ------------------------------------------------------------
-- Responsibility:
--   Handle rocket-launched export trigger:
--   - Show the "exported" message at most once per 30 minutes (via suppressed flag cleared by nth_tick_30min).
--   - Decide destination surface and demolisher type, then spawn it with:
--       * local density cap (choose_position)
--       * global per-surface cap driven by trigger surface evolution (implemented in spawner.spawn)
--   - Record per-surface spawned flags for staged unlocks (manis_boss_demolisher_flag).
-- ------------------------------------------------------------
local boss_demolisher_control = {}

local selector    = require("scripts.services.boss_demolisher_selector")
local spawner     = require("scripts.services.boss_demolisher_spawner")
local probability = require("scripts.services.boss_demolisher_probability")
local quality     = require("scripts.services.quality_assigner")
local util        = require("scripts.common.util")
local TownCenter  = require("scripts.services.town_center_resolver")

local function strip_alt_suffix(name)
  return (name:gsub("%-alt$", ""))
end

-- ----------------------------
-- ロケット発射による輸出イベント
-- ctx: { trigger_surface, silo }
-- ----------------------------
function boss_demolisher_control.on_rocket_launched_export(ctx)
  local trigger_surface = ctx and ctx.trigger_surface
  if not trigger_surface or not trigger_surface.valid then return end

  -- 30分に1回だけ表示（on_nth_tick_30min が suppressed を nil に戻す）
  if not storage.manis_export_message_suppressed then
    util.print({"mani-boss-demolisher-message.boss-demolisher-exported"})
    storage.manis_export_message_suppressed = true
  end

  -- 1) 確率判定（現行仕様では export のみ true 想定）
  if not probability.should_spawn(trigger_surface, ctx, "export") then
    return
  end

  -- 2) 輸出先surfaceを決める（存在するsurfaceのみ）
  local dest_surface = selector.choose_destination_surface(ctx)
  if not dest_surface then return end

  -- 3) 輸出するデモリッシャーを決める（段階解放＋カテゴリ）
  local pick = selector.choose_demolisher(dest_surface, ctx)
  if not pick then return end
  util.debug("pick.name = " .. pick.name)

  -- 4) 配置位置（局所密度capはspawnerが担保）
  local position = spawner.choose_position(dest_surface, { category = pick.category, name = pick.name })
  if not position then return end

  -- 5) 品質（輸出元surfaceの進化度を1回だけ取得して共通利用）
  local source_evo = game.forces.enemy.get_evolution_factor(trigger_surface)

  local q = quality.choose(dest_surface, {
    entity_name = pick.name,
    category = pick.category,
    source_evo = source_evo,
  })

  -- 6) 生成（グローバルcapは spawner.spawn が trigger_evo を使って判定）
  local town_center = TownCenter.resolve(dest_surface)
  local pick_entity_name = pick.name

  local spawned = spawner.spawn{
    surface  = dest_surface,
    name     = pick_entity_name,
    position = position,
    quality  = q,
    category = pick.category,
    town_center = town_center,
    trigger_evo = source_evo,
  }

  if not spawned then
    util.debug({"", "[", dest_surface.name, "] ",
                "SPAWN FAILED: ", {"entity-name." .. pick_entity_name},
                " pos={", position.x, ", ", position.y, "}"})
    return
  end

  -- 7) 出現済みフラグ（段階解放用）
  local entity_base_name = strip_alt_suffix(pick.name)
  storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}
  storage.manis_boss_demolisher_flag[dest_surface.name] = storage.manis_boss_demolisher_flag[dest_surface.name] or {}
  storage.manis_boss_demolisher_flag[dest_surface.name][entity_base_name] = true

  util.debug({"", "[", dest_surface.name, "] ", {"entity-name." .. pick.name},
              " category=", pick.category,
              " pos={", position.x, ", ", position.y, "}"})
end

return boss_demolisher_control