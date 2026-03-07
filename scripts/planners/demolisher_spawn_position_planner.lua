-- __ManisBossDemolisher__/scripts/planners/demolisher_spawn_position_planner.lua
-- ----------------------------
-- 責務:
-- - 選定済みの chunk 座標から chunk 内の spawn position を生成する。
-- - 禁止矩形内に入った場合は外側へ押し出す。
-- - generated chunk の取得・外周判定・territory 解決は行わない。
-- ----------------------------

local M = {}

local DeterministicRandom = require("scripts.util.deterministic_random")

local FORBIDDEN_HALF = 400
local PUSH_TO = 450

local function is_in_forbidden_rect(position)
  return position
    and position.x >= -FORBIDDEN_HALF and position.x <= FORBIDDEN_HALF
    and position.y >= -FORBIDDEN_HALF and position.y <= FORBIDDEN_HALF
end

local function push_out_of_forbidden(position)
  if not is_in_forbidden_rect(position) then
    return position
  end

  if DeterministicRandom.random(1, 2) == 1 then
    position.x = (DeterministicRandom.random(0, 1) == 0) and -PUSH_TO or PUSH_TO
  else
    position.y = (DeterministicRandom.random(0, 1) == 0) and -PUSH_TO or PUSH_TO
  end

  return position
end

local function assert_chunk_coordinate(value, name)
  if type(value) ~= "number" then
    error("MBD_SPAWN_POSITION_PLANNER_INVALID_" .. name)
  end

  if value ~= math.floor(value) then
    error("MBD_SPAWN_POSITION_PLANNER_NON_INTEGER_" .. name)
  end
end

local function random_position_in_chunk(chunk_x, chunk_y)
  local base_x = chunk_x * 32
  local base_y = chunk_y * 32

  return {
    x = base_x + DeterministicRandom.random(0, 31),
    y = base_y + DeterministicRandom.random(0, 31),
  }
end

function M.choose_position_from_chunk(chunk_x, chunk_y)
  assert_chunk_coordinate(chunk_x, "CHUNK_X")
  assert_chunk_coordinate(chunk_y, "CHUNK_Y")

  local position = random_position_in_chunk(chunk_x, chunk_y)
  return push_out_of_forbidden(position)
end

return M