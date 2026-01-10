-- scripts.common.util.lua
local util = {}

-- デバッグ出力フラグ
util.DEBUG_ENABLED = false

function util.print(msg)
  if game and msg then
    game.print(msg)
  end
end

function util.debug(msg)
  if not util.DEBUG_ENABLED then return end
  if game and msg then
    game.print(msg)
  end
end

return util