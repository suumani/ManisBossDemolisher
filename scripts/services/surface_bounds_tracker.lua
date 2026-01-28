-- __ManisBossDemolisher__/scripts/services/surface_bounds_tracker.lua
-- ----------------------------
-- Surface bounds tracking (AABB)
-- ----------------------------
local M = {}

local function ensure(surface_name)
  storage.manis_surface_bounds = storage.manis_surface_bounds or {}
  storage.manis_surface_bounds[surface_name] = storage.manis_surface_bounds[surface_name] or {
    min_x = 0, max_x = 0,
    min_y = 0, max_y = 0,
    initialized = false,
  }
  return storage.manis_surface_bounds[surface_name]
end

local function update(bounds, x, y)
  if not bounds.initialized then
    bounds.min_x, bounds.max_x = x, x
    bounds.min_y, bounds.max_y = y, y
    bounds.initialized = true
    return
  end
  if x < bounds.min_x then bounds.min_x = x end
  if x > bounds.max_x then bounds.max_x = x end
  if y < bounds.min_y then bounds.min_y = y end
  if y > bounds.max_y then bounds.max_y = y end
end

-- Responsibility:
-- Expand AABB bounds when a chunk is generated.
function M.on_chunk_generated(event)
  local surface = event.surface
  if not surface or not surface.valid then return end

  local b = ensure(surface.name)

  -- chunk position is in chunks; convert to tile coordinates (chunk size 32)
  local cx, cy = event.position.x, event.position.y
  local x = cx * 32
  local y = cy * 32

  update(b, x, y)
end

return M