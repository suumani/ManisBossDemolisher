-- __ManisBossDemolisher__/scripts/executors/demolisher_spawn_executor.lua
-- ----------------------------
-- 責務:
-- - territory 解決済みの条件で segmented unit を生成する。
-- ----------------------------

local M = {}

local function resolve_force_name(force_value)
  local force_name = force_value
  if type(force_name) == "userdata" then
    force_name = force_name.name
  end
  if not force_name or force_name == "" then
    force_name = "enemy"
  end
  return force_name
end

local function resolve_quality_name(quality_value)
  local quality_name = quality_value
  if type(quality_name) == "userdata" then
    quality_name = quality_name.name
  end
  if not quality_name or quality_name == "" then
    quality_name = "normal"
  end
  return quality_name
end

function M.spawn(ctx)
  local surface = ctx and ctx.surface
  if not surface or not surface.valid then
    return nil
  end

  if not ctx.name or not ctx.position or not ctx.territory then
    return nil
  end

  local entity = surface.create_segmented_unit({
    name = ctx.name,
    position = ctx.position,
    force = resolve_force_name(ctx.force or "enemy"),
    quality = resolve_quality_name(ctx.quality or "normal"),
    territory = ctx.territory,
  })

  if entity and entity.valid then
    return {
      success = true,
      entity = entity,
    }
  end

  return nil
end

return M