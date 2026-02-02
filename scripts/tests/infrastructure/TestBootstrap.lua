-- scripts/tests/infrastructure/TestBootstrap.lua
-- ------------------------------------------------------------
-- Responsibility:
--   Bootstrap utilities for MBD test packs.
--   - Enable a pack in TestRuntime.
--   - Apply pack config.
--   - Clear test-only execution state (NOT the whole world).
-- Notes:
--   - This module must NOT reset unrelated game state broadly.
--   - It may clear test-owned storage keys and some MBD-owned transient flags if pack requests it.
-- ------------------------------------------------------------
local B = {}

local Runtime = require("scripts.tests.infrastructure.TestRuntime")
local Config  = require("scripts.tests.infrastructure.TestConfig")

-- Keys that are safe to clear for repeatable tests (owned by MBD).
local function clear_mbd_transients()
  -- Export message suppression is transient and safe to reset for tests.
  storage.manis_export_message_suppressed = nil
  storage.manis_boss_demolisher_flag = nil
end

-- Keys owned by Manis_lib virtual manager (test may need repeatability).
local function clear_virtual_store()
  storage.virtual_entities = nil
  storage.virtual_id_seq = nil
end

-- Pack-level bootstrap:
-- opts = {
--   clear_virtual = bool,
--   clear_mbd_transients = bool,
--   export_dest_surface_name = string|nil,
--   export_force_pick = {name=string, category=string}|nil
-- }
function B.start_pack(pack_id, opts)
  opts = opts or {}
  storage = storage or {}

  Runtime.enable(pack_id)

  if opts.clear_mbd_transients then
    clear_mbd_transients()
  end
  if opts.clear_virtual then
    clear_virtual_store()
  end

  -- Apply optional deterministic config
  if opts.export_dest_surface_name then
    Config.set_export_dest_surface_name(pack_id, opts.export_dest_surface_name)
  end
  if opts.export_force_pick and opts.export_force_pick.name then
    Config.set_export_force_pick(pack_id, opts.export_force_pick.name, opts.export_force_pick.category)
  end
end

function B.end_pack()
  -- keep configs unless caller clears explicitly; pack runs may want to inspect afterward
  Runtime.disable()
end

return B