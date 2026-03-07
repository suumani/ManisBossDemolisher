-- __ManisBossDemolisher__/scripts/gateways/generated_chunk_index_gateway.lua
-- ----------------------------
-- 責務:
-- - ManisLibGeneratedChunkIndex remote interface の唯一の読取窓口になる。
-- - interface 存在・ready・keys 契約を検証する。
-- - generated chunk membership を問い合わせる。
-- - 契約違反は前提違反として error() する。
-- ----------------------------

local M = {}

local Logger = require("scripts.logging.logger")

local INTERFACE_NAME = "manis_generated_chunk_index"

local function assert_surface(surface)
  if not surface or not surface.valid then
    error("MBD_GENERATED_CHUNK_INDEX_SURFACE_INVALID")
  end
end

local function assert_interface_available()
  if not remote or not remote.interfaces or not remote.interfaces[INTERFACE_NAME] then
    error("MBD_GENERATED_CHUNK_INDEX_INTERFACE_MISSING")
  end
end

local function assert_boolean(value, error_code)
  if type(value) ~= "boolean" then
    error(error_code)
  end
end

local function assert_integer(value, name)
  if type(value) ~= "number" then
    error("MBD_GENERATED_CHUNK_INDEX_" .. name .. "_NOT_NUMBER")
  end
  if value ~= math.floor(value) then
    error("MBD_GENERATED_CHUNK_INDEX_" .. name .. "_NOT_INTEGER")
  end
end

local function assert_keys_array(keys, surface)
  if type(keys) ~= "table" then
    error("MBD_GENERATED_CHUNK_INDEX_KEYS_NOT_TABLE: surface=" .. surface.name)
  end

  if #keys <= 0 then
    error("MBD_GENERATED_CHUNK_INDEX_KEYS_EMPTY: surface=" .. surface.name)
  end

  for i = 1, #keys do
    if type(keys[i]) ~= "string" then
      error(
        "MBD_GENERATED_CHUNK_INDEX_KEY_NOT_STRING: surface="
          .. surface.name
          .. " index="
          .. tostring(i)
      )
    end
  end
end

function M.assert_ready(surface)
  assert_surface(surface)
  assert_interface_available()

  local ready = remote.call(INTERFACE_NAME, "is_ready", surface.index)
  assert_boolean(ready, "MBD_GENERATED_CHUNK_INDEX_READY_NOT_BOOLEAN: surface=" .. surface.name)

  if ready ~= true then
    error("MBD_GENERATED_CHUNK_INDEX_NOT_READY: surface=" .. surface.name)
  end
end

function M.get_generated_chunk_keys(surface)
  assert_surface(surface)
  M.assert_ready(surface)

  local keys = remote.call(INTERFACE_NAME, "get_generated_chunk_keys", surface.index)
  assert_keys_array(keys, surface)

  Logger.debug({
    "[GeneratedChunkIndex][Keys]",
    " surface=", surface.name,
    " surface_index=", surface.index,
    " key_count=", #keys,
  })

  return keys
end

function M.has_chunk(surface, chunk_x, chunk_y)
  assert_surface(surface)
  M.assert_ready(surface)
  assert_integer(chunk_x, "CHUNK_X")
  assert_integer(chunk_y, "CHUNK_Y")

  local exists = remote.call(INTERFACE_NAME, "has_chunk", surface.index, chunk_x, chunk_y)
  assert_boolean(
    exists,
    "MBD_GENERATED_CHUNK_INDEX_HAS_CHUNK_NOT_BOOLEAN: surface=" .. surface.name
  )

  return exists
end

return M