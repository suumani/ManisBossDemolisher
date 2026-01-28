-- __ManisBossDemolisher__/scripts/services/BreedingDemolisherSpawner.lua
local Spawner = {}

local VirtualMgr = require("__Manis_lib__/scripts/managers/VirtualEntityManager")

function Spawner.process_virtual_queue(event)
    local surface = event.surface
    if not surface or not surface.valid then return end

    local area = event.area

    -- ★修正: エリア検索を使ってリスト取得
    local entries = VirtualMgr.find_in_area(surface, area)
    if #entries == 0 then return end

    for _, entry in ipairs(entries) do
        local data = entry.data
        
        local entity = surface.create_entity{
            name      = data.name,
            position  = entry.position,
            force     = data.force or "enemy",
            quality   = data.quality,
            direction = defines.direction.north
        }

        if entity then
            -- ★修正: ID指定で削除
            VirtualMgr.remove(surface, entry.id)
        end
    end
end

return Spawner