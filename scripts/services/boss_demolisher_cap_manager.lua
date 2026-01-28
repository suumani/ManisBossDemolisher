-- __ManisBossDemolisher__/scripts/services/boss_demolisher_cap_manager.lua
local CapManager = {}

-- 依存: Manis_libの計算機（純粋関数）
-- 外部Mod参照のためスラッシュ区切り
local Calculator = require("__Manis_lib__/scripts/logic/DemolisherCapCalculator")
local util = require("scripts.common.util")

local POLICY = {
    -- 初期値設定
    GLOBAL_BASE_CAP = 40,     -- 全体の上限（Combat系はこれに縛られる）
    FATAL_BASE_CAP  = 40,     -- Fatal系の特別枠上限

    REDUCTION_STEP = 0.05,    -- 1レベルごとの減少率 (5%)
    
    -- 下限設定
    GLOBAL_FLOOR = 10,        -- 全体上限は10以下にはならない
    FATAL_FLOOR  = 10,         -- Fatal上限は1以下にはならない（0にはしない）

    TECH_NAME = "manis-demolisher-cap-down" -- 対象の研究名
}

--- 現在の研究完了数を取得する内部関数
local function get_research_level(force)
    if not force or not force.technologies then return 0 end
    
    local tech = force.technologies[POLICY.TECH_NAME]
    if not tech then 
        -- 研究が存在しない場合はLv0扱い
        return 0 
    end

    -- 無限研究のレベル計算: (現在のレベル)
    -- 未完了なら0になるよう max(0, ...)
    return math.max(0, tech.level)
end

--- 現在の「全体上限数（Global Cap）」を計算して返す
-- Combat系はこの値を超えてスポーンできない
function CapManager.get_global_cap(force)
    local level = get_research_level(force)
    return Calculator.calculate(POLICY.GLOBAL_BASE_CAP, level, POLICY.REDUCTION_STEP, POLICY.GLOBAL_FLOOR)
end

--- 現在の「Fatal上限数（Fatal Cap）」を計算して返す
-- Fatal系はこの値を超えてスポーンできない（全体上限は無視できる）
function CapManager.get_fatal_cap(force)
    local level = get_research_level(force)
    return Calculator.calculate(POLICY.FATAL_BASE_CAP, level, POLICY.REDUCTION_STEP, POLICY.FATAL_FLOOR)
end

return CapManager