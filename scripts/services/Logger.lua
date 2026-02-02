-- __ManisBossDemolisher__/scripts/services/Logger.lua
-- ------------------------------------------------------------
-- Responsibility:
--   Logging facade for ManisBossDemolisher.
--   - Uses Manis_Logger via remote interface when available.
--   - Falls back to Factorio log() when Manis_Logger is not installed.
--   - Centralizes tag/prefix usage to keep call sites clean.
-- ------------------------------------------------------------
local L = {}

util = require("__ManisBossDemolisher__/scripts/common/util.lua")

local TAG = "ManisBossDemolisher"
local SOURCE_KEY = "manisbossdemolisher"

local function call_remote(level, msg, player_index)
  if remote.interfaces["manis_logger"] then
    remote.call("manis_logger", level, TAG, msg, player_index, SOURCE_KEY)
    return true
  end
  return false
end

local function fallback(level, msg)
  -- minimal fallback
  log("[" .. TAG .. "][" .. string.upper(level) .. "] " .. tostring(msg))
end

local function emit(level, msg, player_index)
  if not call_remote(level, msg, player_index) then
    fallback(level, msg)
  end
end

function L.debug(msg, player_index) emit("debug", msg, player_index) end
function L.info(msg, player_index)  emit("info",  msg, player_index) end
function L.warn(msg, player_index)  emit("warn",  msg, player_index) end
function L.error(msg, player_index) emit("error", msg, player_index) end

return L