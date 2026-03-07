-- __ManisBossDemolisher__/control.lua
-- ----------------------------
-- 責務:
-- - ランタイム初期化を行う。
-- - 旧storageのマイグレーションを行う。
-- - イベント登録を一元化する。
-- ----------------------------

local RegisterEvents = require("scripts.bootstrap.register_events")
local InitStorage = require("scripts.bootstrap.init_storage")
local MigrateLegacyStorage = require("scripts.bootstrap.migrate_legacy_storage")

local function init()
  InitStorage.initialize()
  MigrateLegacyStorage.migrate()
end

RegisterEvents.register()

script.on_init(init)
script.on_configuration_changed(function()
  init()
end)