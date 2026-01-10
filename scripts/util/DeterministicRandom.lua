-- __ManisBossDemolisher__/scripts/util/DeterministicRandom.lua
-- 責務: Factorio公式の同期乱数(LuaRandomGenerator)を使い、math.random互換APIを提供する。
--       math.random() / math.random(min,max) の置換を最小コストで実現し、マルチ同期を壊さない。
local DeterministicRandom = {}

local DEFAULT_SEED = 1001001

--- init(seed)
--- 責務: storage に同期乱数生成器を確実に用意する（on_init/on_configuration_changedから呼ぶ）。
function DeterministicRandom.init(seed)
  if not storage then error("storage is not available. Call from runtime stage.") end
  if not storage._det_rand_rng then
    storage._det_rand_rng = game.create_random_generator(seed or DEFAULT_SEED)
  end
end

--- _rng()
--- 責務: 初期化済みの RNG を取得する（未初期化なら安全に初期化する）。
local function _rng()
  if not storage._det_rand_rng then
    -- 保険: 通常は init() で生成される
    storage._det_rand_rng = game.create_random_generator(DEFAULT_SEED)
  end
  return storage._det_rand_rng
end

--- random([min], [max])
--- 責務: math.random互換。
--- - random() -> [0, 1) の実数（math.random() の代替として使用）
--- - random(max) / random(min,max) -> 整数（両端含む）
function DeterministicRandom.random(a, b)
  local rng = _rng()

  -- random() -> real [0,1)
  if a == nil and b == nil then
    return rng()
  end

  -- random(max)
  if b == nil then
    local max = tonumber(a)
    if not max then error("DeterministicRandom.random(max): max must be a number") end
    if max < 1 then error("DeterministicRandom.random(max): max must be >= 1") end
    return 1 + math.floor(rng() * max)
  end

  -- random(min, max)
  local min = tonumber(a)
  local max = tonumber(b)
  if not min or not max then error("DeterministicRandom.random(min,max): args must be numbers") end
  if max < min then error("DeterministicRandom.random(min,max): max must be >= min") end

  return min + math.floor(rng() * (max - min + 1))
end

return DeterministicRandom