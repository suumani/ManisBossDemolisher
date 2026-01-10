-- scripts/services/town_center_resolver.lua
local R = {}

local function dist2(p)
  return p.x * p.x + p.y * p.y
end

-- town_center定義：
-- 1) 研究所（lab）があれば、そのうち最も(0,0)に近い
-- 2) なければロケットサイロ（rocket-silo）のうち最も(0,0)に近い
-- 3) なければ(0,0)
function R.resolve(surface)
  -- 1) lab
  local labs = surface.find_entities_filtered{ type = "lab" }
  local best = nil
  local bestd = nil
  if labs and #labs > 0 then
    for _, e in pairs(labs) do
      local p = e.position
      local d = dist2(p)
      if bestd == nil or d < bestd then
        bestd = d
        best = { x = p.x, y = p.y }
      end
    end
    return best
  end

  -- 2) rocket-silo
  local silos = surface.find_entities_filtered{ type = "rocket-silo" }
  if silos and #silos > 0 then
    for _, e in pairs(silos) do
      local p = e.position
      local d = dist2(p)
      if bestd == nil or d < bestd then
        bestd = d
        best = { x = p.x, y = p.y }
      end
    end
    return best
  end

  -- 3) fallback
  return { x = 0, y = 0 }
end

return R