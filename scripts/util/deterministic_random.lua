-- __ManisBossDemolisher__/scripts/util/deterministic_random.lua
-- ----------------------------
-- 責務:
-- - Factorio公式の同期乱数 LuaRandomGenerator を提供する。
-- - math.random 互換の最小APIを提供する。
-- ----------------------------

local M = {}

local DEFAULT_SEED = 1001001

function M.init(seed)
  if not storage then
    error("storage is not available. Call from runtime stage.")
  end

  if not storage._det_rand_rng then
    storage._det_rand_rng = game.create_random_generator(seed or DEFAULT_SEED)
  end
end

local function rng()
  if not storage._det_rand_rng then
    storage._det_rand_rng = game.create_random_generator(DEFAULT_SEED)
  end

  return storage._det_rand_rng
end

function M.random(a, b)
  local random_generator = rng()

  if a == nil and b == nil then
    return random_generator()
  end

  if b == nil then
    local max_value = tonumber(a)
    if not max_value then
      error("DeterministicRandom.random(max): max must be a number")
    end
    if max_value < 1 then
      error("DeterministicRandom.random(max): max must be >= 1")
    end

    return 1 + math.floor(random_generator() * max_value)
  end

  local min_value = tonumber(a)
  local max_value = tonumber(b)

  if not min_value or not max_value then
    error("DeterministicRandom.random(min,max): args must be numbers")
  end
  if max_value < min_value then
    error("DeterministicRandom.random(min,max): max must be >= min")
  end

  return min_value + math.floor(random_generator() * (max_value - min_value + 1))
end

return M