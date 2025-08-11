local Save = require("src.systems.save")
local Config = require("src.game.config")
local Banner = require("src.ui.banner")

local Cosmetics = {}

local FILENAME = 'cosmetics.lua'

local state

-- Dynamic color: smoothly cycle through RGB hues
local function rgbTripColor(time)
  local t = time * 0.6
  local r = 0.5 + 0.5 * math.sin(t)
  local g = 0.5 + 0.5 * math.sin(t + 2.0944) -- +120°
  local b = 0.5 + 0.5 * math.sin(t + 4.1888) -- +240°
  return { r, g, b, 1.0 }
end

local function ensure()
  if state then return state end
  -- default: nothing unlocked, nothing selected (player renders white)
  local data = Save.loadLua(FILENAME, { unlocked = {}, selected = nil })
  -- build quick lookup set
  local set = {}
  if data.unlocked then
    for _, id in ipairs(data.unlocked) do set[id] = true end
  end
  state = {
    unlockedList = data.unlocked or {},
    unlockedSet = set,
    selected = data.selected,
  }
  return state
end

local function persist()
  local s = ensure()
  Save.saveLua(FILENAME, { unlocked = s.unlockedList, selected = s.selected })
end

local function highestUnlockedId()
  local s = ensure()
  local bestIdx, bestId = -1, nil
  for i, c in ipairs(Config.cosmetics) do
    if s.unlockedSet[c.id] and i > bestIdx then
      bestIdx, bestId = i, c.id
    end
  end
  return bestId
end

function Cosmetics.all()
  return Config.cosmetics
end

function Cosmetics.isUnlocked(id)
  local s = ensure()
  return s.unlockedSet[id] or false
end

function Cosmetics.unlock(id, opts)
  local s = ensure()
  if not s.unlockedSet[id] then
    table.insert(s.unlockedList, id)
    s.unlockedSet[id] = true
    if opts and opts.silent then
      -- no banner
    else
      -- Find cosmetic name for message
      local name = id
      for _, c in ipairs(Config.cosmetics) do if c.id == id then name = c.name break end end
      Banner.trigger("Unlocked: " .. tostring(name))
    end
    -- auto-select highest unlocked cosmetic
    s.selected = highestUnlockedId() or s.selected
    persist()
  end
end

function Cosmetics.checkUnlocks(score)
  local s = ensure()
  for _, c in ipairs(Config.cosmetics) do
    if (not s.unlockedSet[c.id]) and score >= (c.threshold or math.huge) then
      Cosmetics.unlock(c.id)
    end
  end
end

function Cosmetics.select(id)
  local s = ensure()
  if s.unlockedSet[id] then
    s.selected = id
    persist()
  end
end

function Cosmetics.getSelected()
  local s = ensure()
  if s.selected and s.unlockedSet[s.selected] then return s.selected end
  -- fallback to highest unlocked (may be nil if none unlocked yet)
  local best = highestUnlockedId()
  return best
end

function Cosmetics.getColor()
  local id = Cosmetics.getSelected()
  if not id then
    -- no selection/unlocks yet: start white
    return {1,1,1,1}
  end
  if id == 'rgb_trip' then
    local time = love.timer.getTime()
    return rgbTripColor(time)
  end
  for _, c in ipairs(Config.cosmetics) do
    if c.id == id then return c.color end
  end
  -- unknown id: fallback to white
  return {1,1,1,1}
end

return Cosmetics
