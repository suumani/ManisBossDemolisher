-- __ManisBossDemolisher__/control.lua
require("scripts.events.on_chunk_generated")
require("scripts.events.on_entity_died")
require("scripts.events.on_nth_tick_1min")
require("scripts.events.on_nth_tick_30min")
require("scripts.events.on_rocket_launched")

-- tests (release build: comment out)
require("scripts.tests.mbd_test_command")
require("scripts.tests.infrastructure.DeferredTestPump")
require("scripts.tests.packs.export.PackExportBasic")
require("scripts.tests.packs.export.PackExportQuality")
require("scripts.tests.packs.export.PackExportProgression")
require("scripts.tests.packs.export.PackExportCapEdge")
require("scripts.tests.packs.export.PackExportProgressionWorld")
require("scripts.tests.packs.defeated.PackDefeatedFlag")
require("scripts.tests.packs.interaction.PackExportMoveInteraction")
require("scripts.debug.mbd_audit_commands")



require("scripts.tests.packs.move.PackMoveSchedule")

local function migrate_defeated_flag()
  -- Old key: storage.manis_demolisher_killed_surface[surface_name] = true|false
  -- New key: storage.manis_boss_demolisher_flag[surface_name].defeated = true|nil
  --
  -- Idempotent:
  -- - Safe to call multiple times.
  -- - Deletes old key only after applying migration.
  local old = storage.manis_demolisher_killed_surface
  if type(old) ~= "table" then return end

  storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}

  for surface_name, v in pairs(old) do
    if v == true and type(surface_name) == "string" then
      storage.manis_boss_demolisher_flag[surface_name] =
        storage.manis_boss_demolisher_flag[surface_name] or {}

      -- Only set true; never write false.
      storage.manis_boss_demolisher_flag[surface_name].defeated = true
    end
  end

  -- Remove legacy storage to avoid future ambiguity.
  storage.manis_demolisher_killed_surface = nil
end

local function init()
  storage.manis_boss_demolisher_flag = storage.manis_boss_demolisher_flag or {}

  if not storage.virtual_entities then
    storage.virtual_entities = {}
  end

  -- Migration: defeated flag legacy -> new structure
  migrate_defeated_flag()
end

script.on_init(init)
script.on_configuration_changed(init)