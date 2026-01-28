-- デバッグコマンド一覧
-- デモリッシャー一覧 /c local s=game.player.surface; local t=0; local d={}; for _,e in pairs(s.find_entities_filtered{force="enemy"}) do if e.name:find("demolisher") and not e.name:find("segment") and not e.name:find("trail") and not e.name:find("tail") then t=t+1; d[e.name]=(d[e.name]or 0)+1 end end; game.print("Total: "..t); for n,c in pairs(d) do game.print(n..": "..c) end
-- 研究レベル増加 /c game.player.force.technologies["manis-demolisher-cap-down"].level = 21

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