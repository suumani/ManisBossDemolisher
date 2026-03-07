-- __ManisBossDemolisher__/scripts/resolvers/territory_resolver.lua
-- ----------------------------
-- 責務:
-- - position から chunk を計算する。
-- - chunk に紐づく territory を解決する。
-- - territory 未取得は前提違反として error() する。
-- ----------------------------

local M = {}

local function to_chunk_position(position)
  return {
    x = math.floor(position.x / 32),
    y = math.floor(position.y / 32),
  }
end

function M.resolve(surface, position)
  local chunk_position = to_chunk_position(position)
  local territory = surface.get_territory_for_chunk(chunk_position)

  if not territory then
    error(string.format(
      "MBD_TERRITORY_NOT_FOUND: surface=%s chunk={%d,%d} pos={%s,%s}",
      surface.name,
      chunk_position.x,
      chunk_position.y,
      tostring(position.x),
      tostring(position.y)
    ))
  end

  return territory
end

return M