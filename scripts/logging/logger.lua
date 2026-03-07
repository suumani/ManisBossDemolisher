-- __ManisBossDemolisher__/scripts/logging/logger.lua
-- ----------------------------
-- 責務:
-- - ManisBossDemolisher 用のログ出力窓口を提供する。
-- - Manis_Logger があれば remote 経由で使用する。
-- - 無い場合は Factorio の log() へフォールバックする。
-- ----------------------------

local M = {}

local TAG = "ManisBossDemolisher"
local SOURCE_KEY = "manisbossdemolisher"

local function stringify(value)
  if type(value) == "table" then
    if serpent then
      return serpent.line(value, { comment = false })
    end
    return tostring(value)
  end

  return tostring(value)
end

local function call_remote(level, message, player_index)
  if remote.interfaces["manis_logger"] then
    remote.call("manis_logger", level, TAG, message, player_index, SOURCE_KEY)
    return true
  end

  return false
end

local function fallback(level, message)
  log("[" .. TAG .. "][" .. string.upper(level) .. "] " .. stringify(message))
end

local function emit(level, message, player_index)
  if not call_remote(level, message, player_index) then
    fallback(level, message)
  end
end

function M.debug(message, player_index)
  emit("debug", message, player_index)
end

function M.info(message, player_index)
  emit("info", message, player_index)
end

function M.warn(message, player_index)
  emit("warn", message, player_index)
end

function M.error(message, player_index)
  emit("error", message, player_index)
end

return M