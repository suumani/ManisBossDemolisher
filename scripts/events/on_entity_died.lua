-- __ManisBossDemolisher__/scripts/events/on_entity_died.lua
-- ----------------------------
-- デモリッシャー撃破フラグ更新
-- ----------------------------

local EntityNames = require("scripts.defines.EntityNames")

script.on_event(defines.events.on_entity_died, function(event)
    local entity = event.entity

    -- demolisher撃破のみ対象（名前判定で十分）
    if not (entity.name and entity.name:find("demolisher", 1, true)) then
        return
    end

    local surface = entity.surface

    storage.manis_demolisher_killed_surface = storage.manis_demolisher_killed_surface or {}
    storage.manis_demolisher_killed_surface[surface.name] = true
end)