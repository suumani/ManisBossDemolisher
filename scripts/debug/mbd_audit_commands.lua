-- __ManisBossDemolisher__/scripts/commands/mbd_audit_commands.lua
-- ------------------------------------------------------------
-- Responsibility:
--   Investigation commands for Manis Boss Demolisher.
--   - Count demolishers per surface (physical + virtual).
-- Notes:
--   - Command runs inside this mod, so it can access game + storage.
--   - Output goes to log (Manis Logger) and also to player chat when available.
-- ------------------------------------------------------------
local DemolisherNames = require("__Manis_definitions__/scripts/definition/DemolisherNames")
local Log = require("__Manis_Logger__/scripts/services/Log")

local TARGET_SURFACES = { "nauvis", "fulgora", "gleba", "vulcanus", "aquilo" }

local function say(cmd, msg)
  -- Prefer in-game chat when executed by a player, but always log.
  Log.info(msg)
  if cmd and cmd.player_index then
    local p = game.get_player(cmd.player_index)
    if p then p.print(msg) end
  end
end

local function count_physical(surface)
  if not surface or not surface.valid then return 0 end
  local ents = surface.find_entities_filtered({
    force = "enemy",
    name = DemolisherNames.ALL
  })
  return #ents
end

-- Minimal virtual counter:
-- Assumes Manis_lib virtual manager uses storage.virtual_entities.
-- We count entries whose (name or entity_name) is in DemolisherNames.ALL
-- and whose surface matches.
local function build_name_set(list)
  local s = {}
  for _, n in ipairs(list or {}) do s[n] = true end
  return s
end
local DEMO_SET = build_name_set(DemolisherNames.ALL)

local function count_virtual(surface_name)
  local vstore = storage and storage.virtual_entities
  if type(vstore) ~= "table" then return 0 end

  local function is_demo_payload(payload)
    if type(payload) ~= "table" then return false end
    local name = payload.name or payload.entity_name
    if type(name) ~= "string" or not DEMO_SET[name] then return false end
    return true
  end

  local count = 0

  -- Pattern A: vstore[surface_name] = { ... }
  local bucket = vstore[surface_name]
  if type(bucket) == "table" then
    for _, payload in pairs(bucket) do
      if is_demo_payload(payload) then count = count + 1 end
    end
    return count
  end

  -- Pattern B: vstore = { ...payloads... } with payload.surface_name
  for _, payload in pairs(vstore) do
    if is_demo_payload(payload) then
      local sn = payload.surface_name or payload.surface
      if sn == surface_name then
        count = count + 1
      end
    end
  end

  return count
end

local function run_audit(cmd)
  storage = storage or {}

  say(cmd, "[MBD][Audit] demolisher count START")
  for _, sname in ipairs(TARGET_SURFACES) do
    local s = game.surfaces[sname]
    if not s then
      say(cmd, string.format("[MBD][Audit] surface=%s missing", sname))
    else
      local phys = count_physical(s)
      local virt = count_virtual(sname)
      say(cmd, string.format("[MBD][Audit] surface=%s physical=%d virtual=%d total=%d", sname, phys, virt, phys + virt))
    end
  end
  say(cmd, "[MBD][Audit] demolisher count END")
end

commands.add_command(
  "mbd-audit-demolisher-count",
  "Audit: count demolishers (physical+virtual) per surface",
  run_audit
)