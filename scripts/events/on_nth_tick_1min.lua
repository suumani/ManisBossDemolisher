-- __ManisBossDemolisher__/scripts/events/on_nth_tick_1min.lua
local Runner = require("scripts.services.BossDemolisherMovePlanRunner")

-- テストランナー切り替え
-- local CapTestRunner = require("scripts.debug.CapTestRunner")
-- local WarpTestRunner = require("scripts.debug.WarpTestRunner")

script.on_nth_tick(3600, function()
  -- 通常の移動ロジック（本番用）
  -- ※テスト中は「テストランナー」が強制実行するので、二重実行にならないようここをコメントアウトしても良いが、
  --   WarpTestRunner内で回数制限や確率制限を無視して呼んでいるなら、共存していても問題ない（2回動くだけ）。
  Runner.run_one_step_if_present_all_surfaces()

  -- 【デバッグ】ワープ挙動確認用
  -- WarpTestRunner.run()
  
  -- 【デバッグ】Cap確認用
  -- CapTestRunner.run()
end)