-- __ManisBossDemolisher__/scripts/services/ModRandomProvider.lua
local P = {}
local STORAGE_KEY = "_mbd_rng"
local DEFAULT_SEED = 1001001

function P.get()
  storage[STORAGE_KEY] = storage[STORAGE_KEY] or game.create_random_generator(DEFAULT_SEED)
  return storage[STORAGE_KEY]
end

return P