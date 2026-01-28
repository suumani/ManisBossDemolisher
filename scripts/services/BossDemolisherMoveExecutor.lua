-- __ManisBossDemolisher__/scripts/services/BossDemolisherMoveExecutor.lua
-- Responsibility:
--   Libの共通実行器に対して、BossMod固有の「対象抽選（policy）」と「乱数注入」を結線する。

local E = {}

local StepExecutor = require("__Manis_lib__/scripts/domain/demolisher/move/DemolisherMoveStepExecutor")
local VirtualMgr   = require("__Manis_lib__/scripts/managers/VirtualEntityManager")
local DemolisherQuery = require("__Manis_lib__/scripts/queries/DemolisherQuery")
local MovePolicy   = require("scripts.policies.boss_demolisher_move_policy")
local ModRandomProvider = require("scripts.services.ModRandomProvider")
local util         = require("scripts.common.util")
local Categories   = require("scripts.defines.demolisher_categories")

-- ■ Adapter Factory
-- 第4引数 id_or_nil は内部で obj.id を見るため削除
local function create_adapter(surface, obj, is_virt)
    local adapter = {
        valid      = true,
        surface    = surface,
        is_virtual = is_virt
    }

    if is_virt then
        -- === Virtual Entity Case ===
        -- obj is "entry" { id=..., position=..., data=... }
        local d = obj.data
        
        adapter.name = d.name
        
        -- ★修正(4): Positionの参照共有回避（コピー）
        adapter.position = {x = obj.position.x, y = obj.position.y}

        -- ★修正(1): Force/Qualityの正規化 (String化 + デフォルト値)
        -- 過去データや他Modの影響で userdata が混じっていても吸収する
        local f = d.force
        if type(f) == "userdata" then f = f.name end
        adapter.force = f or "enemy"

        local q = d.quality
        if type(q) == "userdata" then q = q.name end
        adapter.quality = q or "normal"

        adapter.direction = defines.direction.north
        
        -- ID保持
        adapter.virtual_id = obj.id
        adapter.virtual_data = d
        adapter.inner_entity = nil

        -- IDがない仮想データは不正とみなして無効化 (Moverの増殖防止規約に準拠)
        if not adapter.virtual_id then
            adapter.valid = false
        end
    else
        -- === Physical Entity Case ===
        adapter.name = obj.name
        adapter.position = obj.position
        adapter.force = obj.force
        adapter.quality = obj.quality
        adapter.direction = obj.direction
        adapter.inner_entity = obj
        adapter.virtual_id = nil
        
        function adapter.to_virtual_data()
            -- Categories.FATAL を使用した集合判定
            local is_fatal = (Categories.FATAL[obj.name] == true)
            
            -- 型統一 (UserDataをStringに変換して保存)
            local q_name = (type(obj.quality) == "userdata") and obj.quality.name or obj.quality
            local f_name = (type(obj.force) == "userdata") and obj.force.name or obj.force

            return {
                name = obj.name,
                quality = q_name,
                force = f_name,
                category = is_fatal and "fatal" or "combat",
                town_center = nil,
                is_fatal = is_fatal
            }
        end
    end
    return adapter
end

-- ■ 対象リスト構築
local function build_move_targets(surface, area, ctx)
    local adapters = {}
    local count_phys = 0
    local count_virt = 0

    -- 1. 実体 (BossMod管理下のものを取得)
    local phys_targets = DemolisherQuery.find_boss_demolishers_range 
                         and DemolisherQuery.find_boss_demolishers_range(surface, area)
                         or DemolisherQuery.find_demolishers_range(surface, area)

    -- 名前フィルタ
    local target_names = MovePolicy.get_target_names(surface.name)
    local name_map = {}
    if target_names then
        for _, n in pairs(target_names) do name_map[n] = true end
    end

    for _, ent in pairs(phys_targets) do
        if name_map[ent.name] then
            table.insert(adapters, create_adapter(surface, ent, false))
            count_phys = count_phys + 1
        end
    end

    -- 2. 仮想 (IDベース・エリア検索)
    local virtual_entries = VirtualMgr.find_in_area(surface, area)
    for _, entry in ipairs(virtual_entries) do
        local d_name = entry.data and entry.data.name
        if d_name and name_map[d_name] then
            local adp = create_adapter(surface, entry, true)
            if adp.valid then
                table.insert(adapters, adp)
                count_virt = count_virt + 1
            end
        end
    end

    -- ★修正(2): 正確な内訳ログ
    util.debug(string.format("[MoveExecutor] Targets: Phys=%d, Virt=%d", count_phys, count_virt))

    return adapters
end

local function get_rocket_positions(plan)
    return plan.rocket_positions or plan.positions
end

function E.execute_one_step(plan)
    return StepExecutor.execute_one_step(plan, {
        get_surface = function(s) return game.surfaces[s] end,
        get_rocket_positions = get_rocket_positions,
        build_move_targets = build_move_targets,
        compute_move_rate = MovePolicy.compute_move_rate,
        
        -- BossMod固有: 進化度チェックなどを挟む
        can_move = function(name, evo)
            local result = MovePolicy.can_move(name, evo)
            return result
        end,

        get_rng = function() return ModRandomProvider.get() end,
        mod_name = "ManisBossDemolisher",
        log = util.debug
    })
end

return E