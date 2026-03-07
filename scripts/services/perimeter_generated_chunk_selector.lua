-- __ManisBossDemolisher__/scripts/services/perimeter_generated_chunk_selector.lua
-- ----------------------------
-- 責務:
-- - GeneratedChunkIndexGateway から受け取った "cx:cy" 配列を decode する。
-- - keys から bounds を再計算する。
-- - generated chunk のうち外周 chunk のみを抽出する。
-- - 外周 chunk から1件を同期乱数で選択する。
-- - 契約違反は前提違反として error() する。
-- ----------------------------

local M = {}

local DeterministicRandom = require("scripts.util.deterministic_random")
local Logger = require("scripts.logging.logger")

local KEY_PATTERN = "^(-?%d+):(-?%d+)$"

local function assert_keys(keys)
  if type(keys) ~= "table" then
    error("MBD_PERIMETER_SELECTOR_KEYS_NOT_TABLE")
  end

  if #keys <= 0 then
    error("MBD_PERIMETER_SELECTOR_KEYS_EMPTY")
  end
end

local function decode_key(key)
  if type(key) ~= "string" then
    error("MBD_PERIMETER_SELECTOR_KEY_NOT_STRING")
  end

  local sx, sy = string.match(key, KEY_PATTERN)
  if not sx or not sy then
    error("MBD_PERIMETER_SELECTOR_KEY_INVALID: key=" .. tostring(key))
  end

  local cx = tonumber(sx)
  local cy = tonumber(sy)
  if not cx or not cy then
    error("MBD_PERIMETER_SELECTOR_KEY_TONUMBER_FAILED: key=" .. tostring(key))
  end

  return {
    key = key,
    cx = cx,
    cy = cy,
  }
end

local function decode_all(keys)
  local decoded = {}

  for i = 1, #keys do
    decoded[i] = decode_key(keys[i])
  end

  return decoded
end

local function recompute_bounds(decoded_chunks)
  if type(decoded_chunks) ~= "table" or #decoded_chunks <= 0 then
    error("MBD_PERIMETER_SELECTOR_DECODED_EMPTY")
  end

  local first = decoded_chunks[1]
  local bounds = {
    min_cx = first.cx,
    max_cx = first.cx,
    min_cy = first.cy,
    max_cy = first.cy,
  }

  for i = 2, #decoded_chunks do
    local chunk = decoded_chunks[i]

    if chunk.cx < bounds.min_cx then bounds.min_cx = chunk.cx end
    if chunk.cx > bounds.max_cx then bounds.max_cx = chunk.cx end
    if chunk.cy < bounds.min_cy then bounds.min_cy = chunk.cy end
    if chunk.cy > bounds.max_cy then bounds.max_cy = chunk.cy end
  end

  return bounds
end

local function is_perimeter_chunk(chunk, bounds)
  return chunk.cx == bounds.min_cx
    or chunk.cx == bounds.max_cx
    or chunk.cy == bounds.min_cy
    or chunk.cy == bounds.max_cy
end

local function extract_perimeter_chunks(decoded_chunks, bounds)
  local perimeter = {}

  for i = 1, #decoded_chunks do
    local chunk = decoded_chunks[i]
    if is_perimeter_chunk(chunk, bounds) then
      perimeter[#perimeter + 1] = chunk
    end
  end

  if #perimeter <= 0 then
    error("MBD_PERIMETER_SELECTOR_PERIMETER_EMPTY")
  end

  return perimeter
end

function M.select_chunk(keys, surface_name_or_nil)
  assert_keys(keys)

  local decoded_chunks = decode_all(keys)
  local bounds = recompute_bounds(decoded_chunks)
  local perimeter_chunks = extract_perimeter_chunks(decoded_chunks, bounds)

  local selected = perimeter_chunks[DeterministicRandom.random(1, #perimeter_chunks)]
  if not selected then
    error("MBD_PERIMETER_SELECTOR_SELECTION_FAILED")
  end

  Logger.debug({
    "[PerimeterChunkSelector][Selected]",
    " surface=", surface_name_or_nil or "unknown",
    " decoded_count=", #decoded_chunks,
    " bounds={min_cx=", bounds.min_cx,
    ",max_cx=", bounds.max_cx,
    ",min_cy=", bounds.min_cy,
    ",max_cy=", bounds.max_cy, "}",
    " perimeter_count=", #perimeter_chunks,
    " selected_key=", selected.key,
    " selected_chunk={", selected.cx, ",", selected.cy, "}",
  })

  return {
    key = selected.key,
    cx = selected.cx,
    cy = selected.cy,
    bounds = bounds,
    decoded_count = #decoded_chunks,
    perimeter_count = #perimeter_chunks,
  }
end

return M