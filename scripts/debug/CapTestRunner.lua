-- __ManisBossDemolisher__/scripts/debug/CapTestRunner.lua

-- 使い方：on_nth_tick_1min.luaからキック

local Runner = {}

-- 依存関係
local CapManager = require("scripts.services.boss_demolisher_cap_manager")
local Control = require("scripts.control.boss_demolisher_control")
local util = require("scripts.common.util")

-- フラグ判定
function Runner.is_enabled()
    -- utilに定義された固定フラグを参照
    return util.TEST_RUNNER_ENABLED == true
end

-- (以下、audit_caps, trigger_mock_export, run 関数は変更なし)
-- ---------------------------------------------------------
-- 1. キャップ値の監査（Audit）
-- ---------------------------------------------------------
local function audit_caps()
    if not game then return end
    local force = game.forces.player
    
    local global_cap = CapManager.get_global_cap(force)
    local fatal_cap  = CapManager.get_fatal_cap(force)
    
    local tech_name = "manis-demolisher-cap-down"
    local tech = force.technologies[tech_name]
    local lvl = 0
    if tech then 
        lvl = math.max(0, tech.level - tech.prototype.level)
    end

    util.print(string.format(">> [TEST-CAP] Lv:%d | GlobalCap: %d | FatalCap: %d", lvl, global_cap, fatal_cap))
end

local function trigger_mock_export()
    -- 本物のNauvisを取得（siloのsurface用）
    local real_nauvis = game.surfaces["nauvis"]
    if not real_nauvis or not real_nauvis.valid then return end

    -- ★ここが修正ポイント
    -- trigger_surface を本物の nauvis にすると、行き先候補から nauvis が除外されてしまう。
    -- そのため、「fake-planet」という名前の偽オブジェクトを作って渡す。
    local mock_trigger_surface = {
       name = "fake-planet-for-test",
       valid = true
    }

    local mock_ctx = {
        trigger_surface = mock_trigger_surface, -- 偽の発射元
        silo = {
            valid = true,
            position = {x=0, y=0},
            surface = real_nauvis -- サイロ自体は実在する場所に
        }
    }

    util.print(">> [TEST-TRIGGER] Simulating Rocket Export (from fake-planet)...")
    
    -- これで「行き先候補」に nauvis が復活するはず
    Control.on_rocket_launched_export(mock_ctx)
end

function Runner.run()
    if not Runner.is_enabled() then return end

    util.print("================ [DEBUG TEST RUN] ================")
    audit_caps()
    trigger_mock_export()
    util.print("==================================================")
end

return Runner