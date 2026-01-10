-- __ManisBossDemolisher__/scripts/services/BossDemolisherMovePlanStore.lua
local S = {}
local KEY = "_mbd_move_plans" -- storage[KEY][surface_name] = plan

local function root()
  storage[KEY] = storage[KEY] or {}
  return storage[KEY]
end

function S.get(surface_name)
  return root()[surface_name]
end

function S.set(surface_name, plan)
  root()[surface_name] = plan
end

function S.clear(surface_name)
  root()[surface_name] = nil
end

function S.get_all()
  return root()
end

return S