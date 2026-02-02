-- scripts/tests/infrastructure/WorldOracle.lua
-- ------------------------------------------------------------
-- Responsibility:
--   World-state oracle for MBD tests.
--   - Provide canonical ways to observe "world effects" without relying on logs.
--   - Physical: surface.find_entities_filtered (enemy + DemolisherNames.* sets)
--   - Virtual: VirtualEntityManager store counts
-- Notes:
--   - This is test-only infrastructure. Production code must not depend on it.
-- ------------------------------------------------------------
local O = {}

local DemolisherNames = require("__Manis_definitions__/scripts/definition/DemolisherNames")
local DemolisherQuery = require("__Manis_lib__/scripts/queries/DemolisherQuery")
local VirtualMgr = require("__Manis_lib__/scripts/managers/VirtualEntityManager")

local function ensure_surface(surface_name)
  local s = game.surfaces[surface_name]
  if s then return s end
  return game.create_surface(surface_name, {})
end

local function make_name_set(names)
  local m = {}
  for _, n in ipairs(names) do m[n] = true end
  return m
end

local ALL_SET = make_name_set(DemolisherNames.ALL)

-- Normalize quality to string name.
local function normalize_quality(q)
  if q == nil then return "normal" end
  local tq = type(q)
  if tq == "userdata" then
    return q.name or "normal"
  elseif tq == "string" then
    return q
  else
    return "normal"
  end
end

-- ------------------------------------------------------------
-- Detailed snapshot (per-entity), for quality tests etc.
-- Return shape:
--   {
--     [surface_name] = {
--       phy = { [unit_number] = { name=..., quality=..., position={x,y} } },
--       virt = { [virtual_id] = { name=..., quality=..., position={x,y} } },
--     }
--   }
-- ------------------------------------------------------------
function O.snapshot_detail(surface_names)
  local out = {}

  for _, sname in ipairs(surface_names) do
    local surface = game.surfaces[sname]
    local phy_map = {}
    local virt_map = {}

    if surface and surface.valid then
      -- Physical demolishers
      local ents = surface.find_entities_filtered{
        force = "enemy",
        name  = DemolisherNames.ALL,
      }

      for _, e in pairs(ents) do
        if e and e.valid and e.unit_number then
          phy_map[e.unit_number] = {
            name = e.name,
            quality = normalize_quality(e.quality),
            position = { x = e.position.x, y = e.position.y },
          }
        end
      end

      -- Virtual demolishers
      local list = VirtualMgr.get_all_as_list(surface)
      for _, entry in pairs(list) do
        local d = entry and entry.data
        if d and d.name then
          virt_map[entry.id] = {
            name = d.name,
            quality = normalize_quality(d.quality),
            position = { x = entry.position.x, y = entry.position.y },
          }
        end
      end
    end

    out[sname] = { phy = phy_map, virt = virt_map }
  end

  return out
end

-- Return shape:
--   {
--     [surface_name] = {
--       added = { phy = { [unit]=item }, virt = { [id]=item } },
--       removed = { phy = { ... }, virt = { ... } },
--     }
--   }
function O.diff_detail(before, after)
  local out = {}

  for sname, a in pairs(after) do
    local b = before[sname] or { phy = {}, virt = {} }

    local added_phy, removed_phy = {}, {}
    local added_virt, removed_virt = {}, {}

    for k, v in pairs(a.phy or {}) do
      if (b.phy == nil) or (b.phy[k] == nil) then
        added_phy[k] = v
      end
    end
    for k, v in pairs(b.phy or {}) do
      if (a.phy == nil) or (a.phy[k] == nil) then
        removed_phy[k] = v
      end
    end

    for k, v in pairs(a.virt or {}) do
      if (b.virt == nil) or (b.virt[k] == nil) then
        added_virt[k] = v
      end
    end
    for k, v in pairs(b.virt or {}) do
      if (a.virt == nil) or (a.virt[k] == nil) then
        removed_virt[k] = v
      end
    end

    out[sname] = {
      added = { phy = added_phy, virt = added_virt },
      removed = { phy = removed_phy, virt = removed_virt },
    }
  end

  return out
end

-- Find exactly one newly added entity (physical or virtual) on a surface.
-- Returns:
--   { kind="phy"|"virt", id=..., name=..., quality=... }
-- or nil if none added.
function O.find_newly_added_one(surface_name, before_detail, after_detail)
  local b = before_detail[surface_name] or { phy = {}, virt = {} }
  local a = after_detail[surface_name] or { phy = {}, virt = {} }

  local added_count = 0
  local last = nil

  for id, item in pairs(a.phy or {}) do
    if (b.phy == nil) or (b.phy[id] == nil) then
      added_count = added_count + 1
      last = { kind = "phy", id = id, name = item.name, quality = item.quality }
    end
  end

  for id, item in pairs(a.virt or {}) do
    if (b.virt == nil) or (b.virt[id] == nil) then
      added_count = added_count + 1
      last = { kind = "virt", id = id, name = item.name, quality = item.quality }
    end
  end

  if added_count == 0 then
    return nil
  end

  -- Export spec: exactly one entity per execution.
  if added_count ~= 1 then
    return { kind = "error", id = nil, name = nil, quality = nil, added_count = added_count }
  end

  return last
end

-- ----------------------------
-- Physical world oracle
-- ----------------------------
function O.count_physical_demolishers(surface_name)
  local s = ensure_surface(surface_name)
  local ents = DemolisherQuery.find_demolishers(s) or {}
  local c = 0
  for _, e in pairs(ents) do
    if e and e.valid then c = c + 1 end
  end
  return c
end

function O.count_physical_by_name(surface_name, entity_name)
  local s = ensure_surface(surface_name)
  local ents = s.find_entities_filtered{ force = "enemy", name = entity_name } or {}
  local c = 0
  for _, e in pairs(ents) do
    if e and e.valid then c = c + 1 end
  end
  return c
end

-- ----------------------------
-- Virtual world oracle
-- ----------------------------
function O.count_virtual_demolishers(surface_name)
  local s = ensure_surface(surface_name)
  return VirtualMgr.count(s, function(entry)
    return entry and entry.data and entry.data.name and ALL_SET[entry.data.name] == true
  end)
end

function O.count_virtual_by_name(surface_name, entity_name)
  local s = ensure_surface(surface_name)
  return VirtualMgr.count(s, function(entry)
    return entry and entry.data and entry.data.name == entity_name
  end)
end

-- ----------------------------
-- Snapshot / Diff helpers
-- ----------------------------
function O.snapshot(surface_names)
  local snap = {}
  for _, name in ipairs(surface_names) do
    snap[name] = {
      phy = O.count_physical_demolishers(name),
      virt = O.count_virtual_demolishers(name)
    }
  end
  return snap
end

function O.diff(before, after)
  local d = {}
  for name, b in pairs(before) do
    local a = after[name]
    d[name] = { phy = a.phy - b.phy, virt = a.virt - b.virt }
  end
  return d
end

function O.any_increase_on(diff, surface_name)
  local x = diff[surface_name]
  return x and (x.phy > 0 or x.virt > 0)
end

function O.any_increase_anywhere(diff)
  for _, x in pairs(diff) do
    if x.phy > 0 or x.virt > 0 then return true end
  end
  return false
end

local function defeated_flag(surface_name)
  return storage.manis_boss_demolisher_flag
     and storage.manis_boss_demolisher_flag[surface_name]
     and storage.manis_boss_demolisher_flag[surface_name].defeated == true
end

function O.snapshot_flags(surface_names)
  local out = {}
  for _, sname in ipairs(surface_names) do
    out[sname] = {
      killed = defeated_flag(sname)
    }
  end
  return out
end

function O.diff_flags(before, after)
  local out = {}
  for sname, a in pairs(after) do
    local b = before[sname] or {}
    out[sname] = {
      killed = { before = b.killed == true, after = a.killed == true }
    }
  end
  return out
end

return O