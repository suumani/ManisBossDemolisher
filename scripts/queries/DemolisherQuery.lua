-- __ManisBossDemolisher__/scripts/queries/DemolisherQuery.lua
local Q = {}

function Q.find_by_names(surface, names)
  return surface.find_entities_filtered{
    force = "enemy",
    name  = names
  }
end

return Q