-- scripts/tests/infrastructure/TestHooks.lua
-- ------------------------------------------------------------
-- Responsibility:
--   The ONLY gateway production code may use to cooperate with tests.
--   - Reads TestRuntime + TestConfig and exposes "optional overrides".
--   - Must be safe when tests are disabled: returns nil / default values.
-- Notes:
--   - Production modules should not read storage for tests directly.
--   - This module itself may read storage (through TestRuntime/TestConfig).
-- ------------------------------------------------------------
local H = {}

local Runtime = require("scripts.tests.infrastructure.TestRuntime")
local Config  = require("scripts.tests.infrastructure.TestConfig")

-- Key names for scheduler overrides (shared convention)
H.SCHED_MOVE_PLAN_INTERVAL = "move_plan_interval_ticks"  -- 30min scheduler override key (ticks)

function H.is_enabled()
  return Runtime.is_enabled()
end

function H.get_active_pack_id()
  return Runtime.get_active_pack_id()
end

-- ----------------------------
-- Export hooks
-- ----------------------------

-- Optional override: force destination surface name for current pack.
-- Return: string|nil
function H.try_get_export_dest_surface_name()
  if not Runtime.is_enabled() then return nil end
  local pack_id = Runtime.get_active_pack_id()
  if not pack_id then return nil end
  return Config.get_export_dest_surface_name(pack_id)
end

-- Optional override: force pick for current pack.
-- Return: {name=string, category=string|nil}|nil
function H.try_get_export_force_pick()
  if not Runtime.is_enabled() then return nil end
  local pack_id = Runtime.get_active_pack_id()
  if not pack_id then return nil end
  return Config.get_export_force_pick(pack_id)
end

-- Optional override: export cap values for current pack.
-- Return: {global=number|nil, fatal=number|nil}|nil
function H.try_get_export_cap_override()
  if not Runtime.is_enabled() then return nil end
  local pack_id = Runtime.get_active_pack_id()
  if not pack_id then return nil end
  return Config.get_export_cap_override(pack_id)
end

-- Optional override: force spawn position for current pack.
-- Return: {surface_name=string, x=number, y=number}|nil
function H.try_get_export_spawn_position()
  if not Runtime.is_enabled() then return nil end
  local pack_id = Runtime.get_active_pack_id()
  if not pack_id then return nil end
  return Config.get_export_spawn_position(pack_id)
end

-- ----------------------------
-- Scheduler hooks
-- ----------------------------

-- Return override ticks for a scheduler key if present; otherwise nil.
function H.try_get_scheduler_ticks(scheduler_key)
  if not Runtime.is_enabled() then return nil end
  local pack_id = Runtime.get_active_pack_id()
  if not pack_id then return nil end
  return Config.get_scheduler_ticks(pack_id, scheduler_key)
end

-- Convenience: return (override or default)
function H.get_scheduler_ticks_or_default(scheduler_key, default_ticks)
  local t = H.try_get_scheduler_ticks(scheduler_key)
  if type(t) == "number" and t > 0 then return t end
  return default_ticks
end

-- Optional override: minimum planned_total for Move (test mode only).
function H.try_get_move_min_planned_total()
  if not Runtime.is_enabled() then return nil end
  local pack_id = Runtime.get_active_pack_id()
  if not pack_id then return nil end
  return Config.get_move_min_planned_total(pack_id)
end

function H.try_get_move_evo_override()
  if not Runtime.is_enabled() then return nil end
  local pack_id = Runtime.get_active_pack_id()
  if not pack_id then return nil end
  return Config.get_move_evo_override(pack_id)
end

-- Test hook: override evo for Export (test mode only)
function H.try_get_export_evo_override(surface_name)
  if not Runtime.is_enabled() then return nil end
  local pack_id = Runtime.get_active_pack_id()
  if not pack_id then return nil end
  return Config.get_export_evo_override(pack_id, surface_name)
end

function H.try_get_export_quality_roll_override()
  if not Runtime.is_enabled() then return nil end
  local pack_id = Runtime.get_active_pack_id()
  if not pack_id then return nil end
  local v = Config.get_export_quality_roll_override(pack_id)
  if type(v) == "number" then return v end
  return nil
end

function H.try_get_export_spawn_position()
  if not Runtime.is_enabled() then return nil end
  local pack_id = Runtime.get_active_pack_id()
  if not pack_id then return nil end
  return Config.get_export_spawn_position(pack_id)
end

return H