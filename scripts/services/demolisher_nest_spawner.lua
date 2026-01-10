-- scripts/services/demolisher_nest_spawner.lua
local N = {}

local EntityNames = require("scripts.defines.EntityNames")
local DRand = require("scripts.util.DeterministicRandom")

-- ----------------------------
-- 共通ユーティリティ
-- ----------------------------
local function random_near(pos, r)
  return {
    x = pos.x + (DRand.random() * 2 - 1) * r,
    y = pos.y + (DRand.random() * 2 - 1) * r
  }
end

local function spawn_near(surface, name, center, r)
  local p = surface.find_non_colliding_position(name, center, r, 2)
  if not p then return nil end
  return surface.create_entity{
    name = name,
    position = p,
    force = game.forces.enemy,
  }
end

local function find_demolishers(surface)
  return surface.find_entities_filtered{
    force = game.forces.enemy,
    name  = EntityNames.ALL_DEMOLISHERS
  }
end

-- ----------------------------
-- Nauvis
-- 仕様：
-- ・各デモリッシャーにつき半径100に1つ生成
-- ・1%で gleba-spawner（エッグラフト）
-- ・それ以外は biter/spitter スポナー
-- ----------------------------
function N.spawn_nauvis(surface)
  local demolishers = find_demolishers(surface)
  if #demolishers == 0 then return end

  local biter_spawner   = "biter-spawner"
  local spitter_spawner = "spitter-spawner"
  local eggraft         = "gleba-spawner"

  for _, d in pairs(demolishers) do
    if d.valid then
      local near = random_near(d.position, 100)

      local name
      if eggraft and DRand.random() < 0.01 then
        name = eggraft
      else
        name = biter_spawner
      end

      if name then
        spawn_near(surface, name, near, 100)
      end
    end
  end
end

-- ----------------------------
-- Gleba
-- 仕様：
-- ・各デモリッシャーにつき半径100に1つ生成
-- ・必ず gleba-spawner
-- ----------------------------
function N.spawn_gleba(surface)
  local demolishers = find_demolishers(surface)
  if #demolishers == 0 then return end

  local eggraft = "gleba-spawner"
  if not eggraft then return end

  for _, d in pairs(demolishers) do
    if d.valid then
      local near = random_near(d.position, 100)
      spawn_near(surface, eggraft, near, 100)
    end
  end
end

return N