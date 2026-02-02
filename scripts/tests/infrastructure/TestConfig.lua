-- scripts/tests/infrastructure/TestConfig.lua
-- ------------------------------------------------------------
-- Responsibility:
--   Pack/scenario-level test configuration store for ManisBossDemolisher.
--   - Holds deterministic knobs for tests (forced destination, forced pick, etc.).
--   - Keeps configs separated by pack_id (and optionally scenario_id).
-- Notes:
--   - This is configuration (what we want), not execution state.
-- ------------------------------------------------------------
local C = {}

local STORAGE_KEY = "mbd_test_config"

local function root()
  storage[STORAGE_KEY] = storage[STORAGE_KEY] or {}
  return storage[STORAGE_KEY]
end

local function ensure_pack(pack_id)
  local r = root()
  r.packs = r.packs or {}
  r.packs[pack_id] = r.packs[pack_id] or {}
  return r.packs[pack_id]
end

function C.clear_all()
  storage[STORAGE_KEY] = nil
end

function C.clear_pack(pack_id)
  local r = storage and storage[STORAGE_KEY]
  if not r or not r.packs then return end
  r.packs[pack_id] = nil
end

-- ----------------------------
-- Export-related deterministic knobs
-- ----------------------------
function C.set_export_dest_surface_name(pack_id, surface_name)
  local p = ensure_pack(pack_id)
  p.export = p.export or {}
  p.export.dest_surface_name = surface_name
end

function C.get_export_dest_surface_name(pack_id)
  local r = storage and storage[STORAGE_KEY]
  local p = r and r.packs and r.packs[pack_id]
  return p and p.export and p.export.dest_surface_name or nil
end

function C.set_export_force_pick(pack_id, entity_name, category)
  local p = ensure_pack(pack_id)
  p.export = p.export or {}
  p.export.force_pick_name = entity_name
  p.export.force_pick_category = category
end

function C.get_export_force_pick(pack_id)
  local r = storage and storage[STORAGE_KEY]
  local p = r and r.packs and r.packs[pack_id]
  local e = p and p.export
  if not e or not e.force_pick_name then return nil end
  return { name = e.force_pick_name, category = e.force_pick_category }
end

-- Optional override: force spawn position for Export (pack-level).
-- Stored as { surface_name=string, x=number, y=number }
function C.set_export_spawn_position(pack_id, surface_name, pos)
  local p = ensure_pack(pack_id)
  p.export = p.export or {}
  p.export.spawn_position = { surface_name = surface_name, x = pos.x, y = pos.y }
end

function C.get_export_spawn_position(pack_id)
  local r = storage and storage[STORAGE_KEY]
  local p = r and r.packs and r.packs[pack_id]
  local e = p and p.export
  local v = e and e.spawn_position
  if not v or type(v.surface_name) ~= "string" then return nil end
  if type(v.x) ~= "number" or type(v.y) ~= "number" then return nil end
  return v
end

-- ----------------------------
-- Export cap override (pack-level)
-- ----------------------------
function C.set_export_cap_override(pack_id, combat_cap, fatal_cap)
  local p = ensure_pack(pack_id)
  p.export = p.export or {}
  p.export.cap_override = { global = combat_cap, fatal = fatal_cap }
end

function C.get_export_cap_override(pack_id)
  local r = storage and storage[STORAGE_KEY]
  local p = r and r.packs and r.packs[pack_id]
  local e = p and p.export
  return e and e.cap_override or nil
end


-- ----------------------------
-- Scheduler override knobs (pack-level)
-- ----------------------------
function C.set_scheduler_ticks(pack_id, scheduler_key, ticks)
  local p = ensure_pack(pack_id)
  p.schedulers = p.schedulers or {}
  p.schedulers[scheduler_key] = ticks
end

function C.get_scheduler_ticks(pack_id, scheduler_key)
  local r = storage and storage[STORAGE_KEY]
  local p = r and r.packs and r.packs[pack_id]
  return p and p.schedulers and p.schedulers[scheduler_key] or nil
end

-- ----------------------------
-- Move orchestration knobs (pack-level)
-- ----------------------------
function C.set_move_min_planned_total(pack_id, n)
  local p = ensure_pack(pack_id)
  p.move = p.move or {}
  p.move.min_planned_total = n
end

function C.get_move_min_planned_total(pack_id)
  local r = storage and storage[STORAGE_KEY]
  local p = r and r.packs and r.packs[pack_id]
  return p and p.move and p.move.min_planned_total or nil
end

function C.set_move_evo_override(pack_id, evo)
  local p = ensure_pack(pack_id)
  p.move = p.move or {}
  p.move.evo_override = evo
end

function C.get_move_evo_override(pack_id)
  local r = storage and storage[STORAGE_KEY]
  local p = r and r.packs and r.packs[pack_id]
  return p and p.move and p.move.evo_override or nil
end

-- Export evo override (per surface, pack-level)
function C.set_export_evo_override(pack_id, surface_name, evo)
  local p = ensure_pack(pack_id)
  p.export = p.export or {}
  p.export.export_evo_override = p.export.export_evo_override or {}
  p.export.export_evo_override[surface_name] = evo
end

function C.get_export_evo_override(pack_id, surface_name)
  local r = storage and storage[STORAGE_KEY]
  local p = r and r.packs and r.packs[pack_id]
  local e = p and p.export
  local map = e and e.export_evo_override
  if not map then return nil end
  local v = map[surface_name]
  if type(v) == "number" then return v end
  return nil
end

function C.set_export_quality_roll_override(pack_id, r)
  local p = ensure_pack(pack_id)
  p.export = p.export or {}
  p.export.quality_roll_override = r
end

function C.get_export_quality_roll_override(pack_id)
  local r = storage and storage[STORAGE_KEY]
  local p = r and r.packs and r.packs[pack_id]
  local e = p and p.export
  return e and e.quality_roll_override or nil
end

return C