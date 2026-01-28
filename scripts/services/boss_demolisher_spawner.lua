-- __ManisBossDemolisher__/scripts/services/boss_demolisher_spawner.lua
-- ----------------------------
-- Spawn / Positioning
-- ----------------------------

local S = {}

local VirtualMgr = require("__Manis_lib__/scripts/managers/VirtualEntityManager")
local Categories = require("scripts.defines.demolisher_categories")
local DRand = require("scripts.util.DeterministicRandom")

-- 禁則範囲（この半径内には湧かない）
local FORBIDDEN_HALF = 400
-- 禁則内だった場合の押し出し先
local PUSH_TO = 450
-- 工場が小さい場合の最低検索半径（禁則より大きく設定）
local MIN_SPAWN_RADIUS = 500

local function is_in_forbidden_rect(pos)
  return pos
    and pos.x >= -FORBIDDEN_HALF and pos.x <= FORBIDDEN_HALF
    and pos.y >= -FORBIDDEN_HALF and pos.y <= FORBIDDEN_HALF
end

local function push_out_of_forbidden(pos)
  if not is_in_forbidden_rect(pos) then return pos end
  if DRand.random(1, 2) == 1 then
    pos.x = (DRand.random(0, 1) == 0) and -PUSH_TO or PUSH_TO
  else
    pos.y = (DRand.random(0, 1) == 0) and -PUSH_TO or PUSH_TO
  end
  return pos
end

local function has_in_rect(surface, pos, half, predicate)
  local area = {
    { pos.x - half, pos.y - half },
    { pos.x + half, pos.y + half }
  }
  -- 仕様: Density CheckはPhysicalのみ（Virtualは考慮しない簡便化仕様）
  local ents = surface.find_entities_filtered{ area = area, force = game.forces.enemy }
  for _, e in pairs(ents) do
    if e.valid and predicate(e) then
      return true
    end
  end
  return false
end

local function is_fatal(e)
  return Categories.FATAL[e.name] == true
end

local function is_combat(e)
  return e.name:find("demolisher", 1, true) and not Categories.FATAL[e.name]
end

-- 開拓済み範囲を取得するが、最低半径(MIN_SPAWN_RADIUS)を保証する
local function get_search_bounds_chunks(surface, force) 
    local minx, maxx = math.huge, -math.huge 
    local miny, maxy = math.huge, -math.huge 
    local found = false 
    
    for c in surface.get_chunks() do 
        if force.is_chunk_charted(surface, { x = c.x, y = c.y }) then 
            found = true 
            if c.x < minx then minx = c.x end 
            if c.x > maxx then maxx = c.x end 
            if c.y < miny then miny = c.y end 
            if c.y > maxy then maxy = c.y end 
        end 
    end 
    
    local min_r_chunk = math.ceil(MIN_SPAWN_RADIUS / 32)

    if not found then 
        return { minx = -min_r_chunk, maxx = min_r_chunk, miny = -min_r_chunk, maxy = min_r_chunk } 
    end 

    if maxx < min_r_chunk then maxx = min_r_chunk end
    if minx > -min_r_chunk then minx = -min_r_chunk end
    if maxy < min_r_chunk then maxy = min_r_chunk end
    if miny > -min_r_chunk then miny = -min_r_chunk end

    return { minx = minx, maxx = maxx, miny = miny, maxy = maxy } 
end

-- ----------------------------
-- Position selection
-- ----------------------------
function S.choose_position(surface, opts)
  opts = opts or {}
  local category = opts.category or "combat"

  local force = game.forces.player
  local bounds = get_search_bounds_chunks(surface, force)

  local margin = (category == "fatal") and 6 or 1
  local half = (category == "fatal") and 2000 or 500
  local predicate = (category == "fatal") and is_fatal or is_combat

  local function tile_center_of_chunk(cx, cy)
    return { x = cx * 32 + 16, y = cy * 32 + 16 }
  end

  local function choose_chunk_on_side(side)
    if side == 1 then
      return (bounds.minx - margin), DRand.random(bounds.miny, bounds.maxy)
    elseif side == 2 then
      return (bounds.maxx + margin), DRand.random(bounds.miny, bounds.maxy)
    elseif side == 3 then
      return DRand.random(bounds.minx, bounds.maxx), (bounds.miny - margin)
    else
      return DRand.random(bounds.minx, bounds.maxx), (bounds.maxy + margin)
    end
  end

  local tries = (category == "fatal") and 30 or 15

  for _ = 1, tries do
    local side = DRand.random(1, 4)
    local cx, cy = choose_chunk_on_side(side)
    local pos = tile_center_of_chunk(cx, cy)

    pos = push_out_of_forbidden(pos)

    if not has_in_rect(surface, pos, half, predicate) then
      return pos
    end
  end

  return nil
end

-- ----------------------------
-- Spawn wrapper (Physical & Virtual)
-- ----------------------------

-- ■ 物理スポーン実行（内部用）
-- @param data: {name=string, quality=string|LuaQuality, force=string|LuaForce, town_center=MapPosition|nil}
function S.spawn_physically(surface, position, data)
  local dir = defines.direction.north -- default

  -- 方向計算: 現在地(position)から目的地(town_center)へ向かう
  if data.town_center then
      local dx = data.town_center.x - position.x
      local dy = data.town_center.y - position.y
      if math.abs(dx) >= math.abs(dy) then
        dir = (dx >= 0) and defines.direction.east or defines.direction.west
      else
        dir = (dy >= 0) and defines.direction.south or defines.direction.north
      end
  end

  -- Forceの正規化 (Userdata -> String -> Default)
  local f = data.force
  if type(f) == "userdata" then f = f.name end
  if not f or f == "" then f = "enemy" end
  
  -- Qualityの正規化 (Userdata -> String -> Default)
  local q = data.quality
  if type(q) == "userdata" then q = q.name end
  if not q then q = "normal" end

  return surface.create_entity{
    name      = data.name,
    position  = position,
    force     = f,
    quality   = q,
    direction = dir,
  }
end

-- ■ 公開スポーン関数（Controlから呼ばれる）
-- @return { success=boolean, entity=LuaEntity|nil, virtual=boolean, virtual_id=any|nil }
function S.spawn(ctx)
  local surface = ctx.surface
  if not surface or not surface.valid then return nil end
  if not ctx.name or not ctx.position then return nil end

  -- データ構造の正規化 (VirtualData形式に統一)
  local spawn_data = {
      name        = ctx.name,
      quality     = ctx.quality or "normal",
      force       = "enemy", -- BossModは常にenemy
      category    = ctx.category or "combat", -- デフォルト値設定
      town_center = ctx.town_center,
      is_fatal    = (Categories.FATAL[ctx.name] == true)
  }

  -- 1. 生成済みエリアなら即時スポーン
  if surface.is_chunk_generated(ctx.position) then
      local ent = S.spawn_physically(surface, ctx.position, spawn_data)
      if ent and ent.valid then
          return { success = true, entity = ent, virtual = false, virtual_id = nil }
      else
          return nil -- 生成失敗
      end
  else
      -- 2. 未生成なら仮想キューに入れる
      -- ID管理対応: nilを渡して新規発行
      local vid = VirtualMgr.enqueue(surface, nil, ctx.position, spawn_data)
      
      -- 戻り値を統一フォーマットで返す
      if vid then
          return { success = true, entity = nil, virtual = true, virtual_id = vid }
      else
          return nil -- 保存失敗
      end
  end
end

-- ■ 仮想実体化プロセッサ（イベントから呼ばれる）
function S.process_virtual_queue(event)
    local surface = event.surface
    if not surface or not surface.valid then return end

    local entries = VirtualMgr.find_in_area(surface, event.area)
    if #entries == 0 then return end

    for _, entry in ipairs(entries) do
        -- 物理生成 (データは正規化済み前提だが、spawn_physically側で再ガードが入るため安全)
        local ent = S.spawn_physically(surface, entry.position, entry.data)
        
        if ent and ent.valid then
            -- 成功したら削除 (ID指定)
            VirtualMgr.remove(surface, entry.id)
        else
            -- 失敗時は残す (何もしない)
        end
    end
end

return S