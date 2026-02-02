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
local Logger = require("scripts.services.Logger")
local TownCenter  = require("scripts.services.town_center_resolver")
local CapManager  = require("scripts.services.boss_demolisher_cap_manager")
local TestHooks   = require("scripts.tests.infrastructure.TestHooks")
local DemolisherQuery = require("__Manis_lib__/scripts/queries/DemolisherQuery")
local VirtualMgr  = require("__Manis_lib__/scripts/managers/VirtualEntityManager")
local Categories  = require("scripts.defines.demolisher_categories")

local function get_dest_evo(dest_surface)
  local ov = TestHooks.try_get_export_evo_override(dest_surface.name)
  if type(ov) == "number" then return ov end
  return game.forces.enemy.get_evolution_factor(dest_surface)
end

-- ヘルパー: 現在数を正確に数える（実測 + 仮想）
local function count_total_demolishers(surface)
    -- 1. 実測（マップ上に見えているもの）
    local visible_ents = DemolisherQuery.find_demolishers(surface) or {}
    local p_nonfatal = 0
    local p_fatal = 0
    
    for _, e in pairs(visible_ents) do
        if e.valid then
            if Categories.FATAL[e.name] then 
                p_fatal = p_fatal + 1
            else 
                p_nonfatal = p_nonfatal + 1 
            end
        end
    end

    -- 2. 仮想（未生成エリアで待機しているもの）
    -- ★修正: フィルタ関数は entry を受け取る仕様に適合させる
    local v_fatal = VirtualMgr.count(surface, function(entry) 
        return entry.data and entry.data.is_fatal 
    end)
    
    local v_nonfatal = VirtualMgr.count(surface, function(entry) 
        return entry.data and not entry.data.is_fatal 
    end)

    return (p_nonfatal + v_nonfatal), (p_fatal + v_fatal)
end

-- ----------------------------
-- ロケット発射による輸出イベント
-- ----------------------------
function boss_demolisher_control.on_rocket_launched_export(ctx)
  local trigger_surface = ctx and ctx.trigger_surface
  if not trigger_surface or not trigger_surface.valid then return end

  -- メッセージ表示
  if not storage.manis_export_message_suppressed then
    Logger.debug({"mani-boss-demolisher-message.boss-demolisher-exported"})
    storage.manis_export_message_suppressed = true
  end

  -- 1) 確率判定
  if not probability.should_spawn(trigger_surface, ctx, "export") then
    return
  end

  -- 2) 輸出先surfaceを決める
  local dest_surface = selector.choose_destination_surface(ctx)
  if not dest_surface then return end

  -- 3) 輸出するデモリッシャーを決める
  local pick = selector.choose_demolisher(dest_surface, ctx)
  if not pick then return end
  
  -- ★★★ Cap判定 (修正版) ★★★
  local force = game.forces.player
  
  -- Cap model (confirmed by spec):
  -- combat_cap: applied to (combat + fatal) total
  -- fatal_cap : applied to (fatal only)
  local combat_cap = CapManager.get_combat_cap(force)
  local fatal_cap  = CapManager.get_fatal_cap(force)

  -- Test hook: override caps (test mode only)
  local cap_ov = TestHooks.try_get_export_cap_override()
  if cap_ov then
    if type(cap_ov.global) == "number" then combat_cap = cap_ov.global end
    if type(cap_ov.fatal)  == "number" then fatal_cap  = cap_ov.fatal  end
  end

  local cur_nonfatal, cur_fatal = count_total_demolishers(dest_surface)
  local cur_total = cur_nonfatal + cur_fatal

  local is_fatal_pick = (pick.category == "fatal") or Categories.FATAL[pick.name]

  if is_fatal_pick then
    -- Fatal cap checks fatal count only
    if cur_fatal >= fatal_cap then
      Logger.info(string.format(
        "[Skip] Fatal Cap Reached on %s. Fatal:%d >= Cap:%d (Total:%d Combat:%d)",
        dest_surface.name, cur_fatal, fatal_cap, cur_total, cur_nonfatal
      ))
      return
    end
  else
    -- Combat cap checks total (combat + fatal)
    if cur_total >= combat_cap then
      Logger.info(string.format(
        "[Skip] Combat Cap Reached on %s. Total:%d >= Cap:%d (Combat:%d Fatal:%d FatalCap:%d)",
        dest_surface.name, cur_total, combat_cap, cur_nonfatal, cur_fatal, fatal_cap
      ))
      return
    end
  end
  -- ★★★★★★★★★★★★★★★★★★★

  -- 4) 配置位置
  local position = nil

  local pos_ov = TestHooks.try_get_export_spawn_position()
  if pos_ov and pos_ov.surface_name == dest_surface.name then
    position = { x = pos_ov.x, y = pos_ov.y }
  else
    position = spawner.choose_position(dest_surface, { category = pick.category, name = pick.name })
  end

 if not position then
   Logger.info({
     "[Export][Skip]",
     " reason=no_valid_position",
     " dest=", dest_surface.name,
     " category=", pick.category or "unknown",
     " name=", pick.name or "unknown",
   })
   return
 end

  -- 5) 品質
  local dest_evo = 0
  if dest_surface and dest_surface.valid then
      dest_evo = get_dest_evo(dest_surface)
  end
  
  local q = quality.choose(dest_surface, {
    entity_name = pick.name,
    category = pick.category,
    dest_evo = dest_evo,
  })

  -- 6) 生成実行
  local town_center = TownCenter.resolve(dest_surface)
  local result = spawner.spawn{
    surface   = dest_surface,
    name      = pick.name,
    position  = position,
    quality   = q,
    category = pick.category,
    town_center = town_center,
  }

  if result then
    local mode = result.virtual and "Virtually" or "Physically"
    Logger.info({
      "[Export][Result]",
      " dest=", dest_surface.name,
      " kind=", (result.virtual and "virt" or "phy"),
      " name=", pick.name,
      " pos={", position.x, ",", position.y, "}",
    })

    -- 出現済みフラグ更新
    local entity_base_name = pick.name
    storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}
    storage.manis_boss_demolisher_flag[dest_surface.name] = storage.manis_boss_demolisher_flag[dest_surface.name] or {}
    storage.manis_boss_demolisher_flag[dest_surface.name][entity_base_name] = true
  else
    Logger.debug("[Fail] Spawn failed (Internal error).")
  end
end

return boss_demolisher_control