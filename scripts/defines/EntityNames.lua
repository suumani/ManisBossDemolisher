-- __ManisBossDemolisher__/scripts/defines/EntityNames.lua
local D = {}

-- 個別定数
D.small_demolisher = "small-demolisher"
D.medium_demolisher = "medium-demolisher"
D.big_demolisher = "big-demolisher"

D.manis_behemoth_demolisher = "manis-behemoth-demolisher"

-- speedstar
D.manis_speedstar_small_demolisher = "manis-speedstar-small-demolisher"
D.manis_speedstar_medium_demolisher = "manis-speedstar-medium-demolisher"
D.manis_speedstar_big_demolisher = "manis-speedstar-big-demolisher"
D.manis_speedstar_behemoth_demolisher = "manis-speedstar-behemoth-demolisher"

-- gigantic
D.manis_gigantic_small_demolisher = "manis-gigantic-small-demolisher"
D.manis_gigantic_medium_demolisher = "manis-gigantic-medium-demolisher"
D.manis_gigantic_big_demolisher = "manis-gigantic-big-demolisher"
D.manis_gigantic_behemoth_demolisher = "manis-gigantic-behemoth-demolisher"

-- king
D.manis_crazy_gigantic_king_demolisher = "manis-crazy-gigantic-king-demolisher"

-- 全デモリッシャーの一覧
D.ALL_DEMOLISHERS = {
  D.small_demolisher,
  D.medium_demolisher,
  D.big_demolisher,
  D.manis_behemoth_demolisher,
  D.manis_speedstar_small_demolisher,
  D.manis_speedstar_medium_demolisher,
  D.manis_speedstar_big_demolisher,
  D.manis_speedstar_behemoth_demolisher,
  D.manis_gigantic_small_demolisher,
  D.manis_gigantic_medium_demolisher,
  D.manis_gigantic_big_demolisher,
  D.manis_gigantic_behemoth_demolisher,
  D.manis_crazy_gigantic_king_demolisher,
}

-- ボスのみの一覧（このボスは徘徊範囲を変更する、特にヴルカヌスとフルゴラではこの範囲に限定される）
D.ALL_BOSS_DEMOLISHERS = {
  D.manis_behemoth_demolisher,
  D.manis_speedstar_small_demolisher,
  D.manis_speedstar_medium_demolisher,
  D.manis_speedstar_big_demolisher,
  D.manis_speedstar_behemoth_demolisher,
  D.manis_gigantic_small_demolisher,
  D.manis_gigantic_medium_demolisher,
  D.manis_gigantic_big_demolisher,
  D.manis_gigantic_behemoth_demolisher,
  D.manis_crazy_gigantic_king_demolisher,
}

-- COMBAT DEMOLISHERのみの一覧（このボスは徘徊範囲を変更する、ただしヴルカヌスとフルゴラではボスのみが移動）
D.ALL_COMBAT_DEMOLISHERS = {
  D.small_demolisher,
  D.medium_demolisher,
  D.big_demolisher,
  D.manis_behemoth_demolisher,
  D.manis_speedstar_small_demolisher,
  D.manis_speedstar_medium_demolisher,
  D.manis_speedstar_big_demolisher,
  D.manis_speedstar_behemoth_demolisher,
}
-- 致命的なボスのみの一覧（このボスは徘徊範囲を変更しない）
D.ALL_FATAL_DEMOLISHERS = {
  D.manis_gigantic_small_demolisher,
  D.manis_gigantic_medium_demolisher,
  D.manis_gigantic_big_demolisher,
  D.manis_gigantic_behemoth_demolisher,
  D.manis_crazy_gigantic_king_demolisher,
}

return D