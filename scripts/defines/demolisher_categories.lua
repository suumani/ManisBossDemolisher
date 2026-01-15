-- __ManisBossDemolisher__/scripts/defines/demolisher_categories.lua
local DemolisherNames = require("__Manis_definitions__/scripts/definition/DemolisherNames")

local D = {}

D.FATAL = {}

for _, name in ipairs(DemolisherNames.ALL_FATAL) do
  D.FATAL[name] = true
end

return D