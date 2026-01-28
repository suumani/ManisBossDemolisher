-- __ManisBossDemolisher__/scripts/debug/WarpTestRunner.lua

-- 使い方：on_nth_tick_1min.luaからキック

local Runner = {}
local PlanRunner = require("scripts.services.BossDemolisherMovePlanRunner")
local PlanStore  = require("scripts.services.BossDemolisherMovePlanStore")
local VirtualMgr = require("__Manis_lib__/scripts/managers/VirtualEntityManager")
local MovePolicy = require("scripts.policies.boss_demolisher_move_policy") -- モンキーパッチ用
local util       = require("scripts.common.util")

-- ■ 設定
local TEST_SURFACE_NAME = "nauvis"
local TEST_ENTITY_NAME  = "manis-small-demolisher-alt"
local TEST_FORCE        = "enemy"

-- ■ ヘルパー関数群
local function get_surface()
    return game.surfaces[TEST_SURFACE_NAME]
end

local function get_distance(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    return math.sqrt(dx * dx + dy * dy)
end

-- 指定位置周辺のデモリッシャーを一掃する
local function clear_area(pos, radius)
    local surface = get_surface()
    -- 1. 実体削除
    local ents = surface.find_entities_filtered{
        position = pos, radius = radius, type = "segmented-unit", force = TEST_FORCE
    }
    for _, e in pairs(ents) do 
        if e.valid then e.destroy() end 
    end
    
    -- 2. 仮想削除 (API変更対応)
    -- remove_entry_by_index は廃止されたため、find_in_area -> remove(id) を使用
    local area = {
        left_top = {x = pos.x - radius, y = pos.y - radius},
        right_bottom = {x = pos.x + radius, y = pos.y + radius}
    }
    local entries = VirtualMgr.find_in_area(surface, area)
    
    for _, e in ipairs(entries) do
        -- 矩形検索なので、円形距離判定を追加
        if get_distance(e.position, pos) <= radius then
            VirtualMgr.remove(surface, e.id)
        end
    end
end

-- チャンクの状態を強制する (Generated / Void)
local function set_chunk_status(pos, is_charted)
    local surface = get_surface()
    local cx = math.floor(pos.x / 32)
    local cy = math.floor(pos.y / 32)
    local chunk_pos = {cx, cy}

    if is_charted then
        surface.request_to_generate_chunks(pos, 1)
        surface.force_generate_chunk_requests()
        surface.request_to_generate_chunks({x=pos.x*32, y=pos.y*32}, 1)
        surface.force_generate_chunk_requests()
    else
        surface.delete_chunk(chunk_pos)
        surface.delete_chunk({x=pos.x, y=pos.y})
    end
end

-- 1ステップ実行する (MoveRateハッキング付き)
local function run_move_step(start_pos, dest_pos)
    local surface = get_surface()
    
    local plan = {
        surface_name     = surface.name,
        rocket_positions = {dest_pos},
        positions        = {dest_pos},
        rect             = {
            left_top     = {x = -10000, y = -10000},
            right_bottom = {x =  10000, y =  10000}
        },
        rows=1, cols=1, order={1}, step=1,
        planned_total=100, moved_so_far=0, created_tick=game.tick
    }
    PlanStore.set(surface.name, plan)
    
    local force = game.forces[TEST_FORCE]
    force.set_evolution_factor(1.0, surface)
    
    -- ★ハッキング開始: 強制的に超高速移動にして距離の壁を突破する
    local original_compute = MovePolicy.compute_move_rate
    MovePolicy.compute_move_rate = function(positions)
        return 10000.0 -- 1万倍速 (射程無限)
    end
    
    PlanRunner.run_one_step_if_present_all_surfaces()
    
    -- ★ハッキング終了: 復元
    MovePolicy.compute_move_rate = original_compute
end

-- ■ テストケース実装
local function test_phy_to_phy()
    local start_pos = {x=20, y=20}
    local dest_pos  = {x=-20, y=-20}
    
    clear_area(start_pos, 50)
    clear_area(dest_pos, 50)
    set_chunk_status(start_pos, true)
    set_chunk_status(dest_pos, true)

    local ent = get_surface().create_entity{name=TEST_ENTITY_NAME, position=start_pos, force=TEST_FORCE}
    if not ent then return "SKIP (Spawn Failed)" end

    run_move_step(start_pos, dest_pos)

    local at_dest = get_surface().find_entities_filtered{position=dest_pos, radius=10, type="segmented-unit"}
    if #at_dest > 0 then return "OK" else return "NG (Target not found at Dest)" end
end

local function test_phy_to_virt()
    local start_pos = {x=40, y=40}
    local dest_pos  = {x=5000, y=5000} 
    
    clear_area(start_pos, 50)
    set_chunk_status(start_pos, true)
    set_chunk_status(dest_pos, false)

    local ent = get_surface().create_entity{name=TEST_ENTITY_NAME, position=start_pos, force=TEST_FORCE}
    if not ent then return "SKIP (Spawn Failed)" end

    run_move_step(start_pos, dest_pos)

    if ent.valid then return "NG (Entity still exists)" end
    
    -- API変更対応: get_entries -> get_all_as_list
    local entries = VirtualMgr.get_all_as_list(get_surface())
    for _, e in pairs(entries) do
        if get_distance(e.position, dest_pos) < 10 then return "OK" end
    end
    return "NG (Virtual entry not found)"
end

local function test_virt_to_phy()
    local start_pos = {x=-5000, y=-5000}
    local dest_pos  = {x=60, y=60}
    
    clear_area(dest_pos, 50)
    clear_area(start_pos, 50)

    -- API変更対応: 第2引数(id)に nil を渡して新規発行させる
    VirtualMgr.enqueue(get_surface(), nil, start_pos, {
        name = TEST_ENTITY_NAME, category = "combat", quality = "normal"
    })
    set_chunk_status(start_pos, false)
    set_chunk_status(dest_pos, true)

    run_move_step(start_pos, dest_pos)

    local at_dest = get_surface().find_entities_filtered{position=dest_pos, radius=10, type="segmented-unit"}
    if #at_dest > 0 then return "OK" else return "NG (Physical entity not spawned)" end
end

local function test_virt_to_virt()
    local start_pos = {x=6000, y=6000}
    local dest_pos  = {x=7000, y=7000}

    clear_area(start_pos, 50)
    clear_area(dest_pos, 50)

    -- API変更対応: 第2引数(id)に nil を渡す
    VirtualMgr.enqueue(get_surface(), nil, start_pos, {
        name = TEST_ENTITY_NAME, category = "combat", quality = "normal"
    })
    set_chunk_status(start_pos, false)
    set_chunk_status(dest_pos, false)

    run_move_step(start_pos, dest_pos)

    -- API変更対応: get_entries -> get_all_as_list
    local entries = VirtualMgr.get_all_as_list(get_surface())
    for _, e in pairs(entries) do
        if get_distance(e.position, dest_pos) < 10 then return "OK" end
    end
    return "NG (Virtual entry not moved to dest)"
end

-- ■ メイン実行部
function Runner.run()
    util.debug("# WarpTestRunner Report")
    
    local r1 = test_phy_to_phy()
    util.debug(string.format(" - [%s] Physical -> Physical (Charted -> Charted)", r1))
    
    local r2 = test_phy_to_virt()
    util.debug(string.format(" - [%s] Physical -> Virtual  (Charted -> Uncharted)", r2))
    
    local r3 = test_virt_to_phy()
    util.debug(string.format(" - [%s] Virtual  -> Physical (Uncharted -> Charted)", r3))
    
    local r4 = test_virt_to_virt()
    util.debug(string.format(" - [%s] Virtual  -> Virtual  (Uncharted -> Uncharted)", r4))
    
    util.debug("---------------------------------------------------")
    if r1=="OK" and r2=="OK" and r3=="OK" and r4=="OK" then
        util.debug("All 4 tests passed.")
    else
        util.debug("Some tests failed.")
    end
end

return Runner