-- __ManisBossDemolisher__/scripts/common/util.lua
local util = {}

-- デバッグ出力フラグ
-- リリース時は必ず false にすること！
util.DEBUG_ENABLED = false

-- リリース時は必ず false にすること！
util.TEST_RUNNER_ENABLED = false

function util.print(msg)
  if game and msg then
    game.print(msg)
  end
end

local OUTPUT_FILE = "ManisBossDemolisher.log"

-- ログ用にデータを文字列化する
local function to_log_string(data)
  local t = type(data)
  if t == "string" then
    return data
  elseif t == "table" then
    -- Factorio標準のシリアライザを使用 (LocalisedString等の構造を確認できる)
    if serpent then
      return serpent.line(data, {comment = false})
    else
      return tostring(data)
    end
  else
    return tostring(data)
  end
end

local function write_line(data)
  local line = to_log_string(data)
  helpers.write_file(OUTPUT_FILE, line .. "\n", true)
end

function util.debug(msg)
  if not util.DEBUG_ENABLED then return end
  -- msg が false の場合も出力したい場合は msg ~= nil 推奨だが、元のロジックを尊重
  if game and msg then
    game.print(msg)
    write_line(msg)
  end
end

return util