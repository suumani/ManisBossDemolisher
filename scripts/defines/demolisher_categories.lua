-- __ManisBossDemolisher__/scripts/defines/demolisher_categories.lua
-- ----------------------------
-- 責務:
-- - fatal 系デモリッシャー名セットを提供する。
-- ----------------------------

local DemolisherNames = require("__Manis_definitions__/scripts/definition/DemolisherNames")

local M = {
  FATAL = {},
}

for _, name in ipairs(DemolisherNames.ALL_FATAL) do
  M.FATAL[name] = true
end

return M