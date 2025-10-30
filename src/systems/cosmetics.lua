local Save = require("src.systems.save")
local Constants = require("src.config.constants")
local Banner = require("src.ui.banner")

local Cosmetics = {}

local FILENAME = 'cosmetics.lua'

local state

-- Dynamic color: smoothly cycle through RGB hues (much faster!)
local function rgbTripColor(time)
  local t = time * 2.5 -- Speed up RGB morphing by ~4x
  local r = 0.5 + 0.5 * math.sin(t)
  local g = 0.5 + 0.5 * math.sin(t + 2.0944) -- +120°
  local b = 0.5 + 0.5 * math.sin(t + 4.1888) -- +240°
  return { r, g, b, 1.0 }
end

-- Ship shape drawing functions
local function drawTriangleShip(x, y, width, height)
  local halfW = width / 2
  local h = height
  love.graphics.polygon("fill",
    x, y - h/2,
    x - halfW, y + h/2,
    x + halfW, y + h/2
  )
end

local function drawDiamondShip(x, y, width, height)
  local halfW = width / 2
  local halfH = height / 2
  love.graphics.polygon("fill",
    x, y - halfH,
    x + halfW, y,
    x, y + halfH,
    x - halfW, y
  )
end

local function drawHexagonShip(x, y, width, height)
  local radius = math.min(width, height) / 2
  local angles = {}
  for i = 0, 5 do
    local angle = (i * math.pi / 3) - math.pi / 2
    table.insert(angles, x + radius * math.cos(angle))
    table.insert(angles, y + radius * math.sin(angle))
  end
  love.graphics.polygon("fill", angles)
end

local function drawArrowShip(x, y, width, height)
  local halfW = width / 2
  local h = height
  love.graphics.polygon("fill",
    x, y - h/2,           -- Top point
    x + halfW/2, y,        -- Right middle
    x + halfW, y + h/2,    -- Right bottom
    x, y + h/4,           -- Bottom center
    x - halfW, y + h/2,    -- Left bottom
    x - halfW/2, y         -- Left middle
  )
end

local function drawCircleShip(x, y, width, height)
  local radius = math.min(width, height) / 2
  love.graphics.circle("fill", x, y, radius)
end

local function drawStarShip(x, y, width, height)
  local outerRadius = math.min(width, height) / 2
  local innerRadius = outerRadius * 0.4
  local points = {}
  
  for i = 0, 9 do
    local angle = (i * math.pi / 5) - math.pi / 2
    local radius = (i % 2 == 0) and outerRadius or innerRadius
    table.insert(points, x + radius * math.cos(angle))
    table.insert(points, y + radius * math.sin(angle))
  end
  
  love.graphics.polygon("fill", points)
end

local shapeDrawers = {
  triangle = drawTriangleShip,
  diamond = drawDiamondShip,
  hexagon = drawHexagonShip,
  arrow = drawArrowShip,
  circle = drawCircleShip,
  star = drawStarShip
}

local function ensure()
  if state then return state end
  -- default: triangle shape, white color, nothing else unlocked
  local data = Save.loadLua(FILENAME, { 
    unlockedColors = {}, 
    unlockedShapes = {"triangle"}, -- Triangle is free by default
    selectedColor = nil, 
    selectedShape = "triangle" 
  })
  
  -- build quick lookup sets
  local colorSet = {}
  if data.unlockedColors then
    for _, id in ipairs(data.unlockedColors) do colorSet[id] = true end
  end
  
  local shapeSet = {}
  if data.unlockedShapes then
    for _, id in ipairs(data.unlockedShapes) do shapeSet[id] = true end
  end
  
  state = {
    unlockedColors = data.unlockedColors or {},
    unlockedColorSet = colorSet,
    unlockedShapes = data.unlockedShapes or {"triangle"},
    unlockedShapeSet = shapeSet,
    selectedColor = data.selectedColor,
    selectedShape = data.selectedShape or "triangle",
  }
  return state
end

local function persist()
  local s = ensure()
  Save.saveLua(FILENAME, { 
    unlockedColors = s.unlockedColors,
    unlockedShapes = s.unlockedShapes,
    selectedColor = s.selectedColor,
    selectedShape = s.selectedShape
  })
end

function Cosmetics.allColors()
  return Constants.ECONOMY.cosmetics.colors
end

function Cosmetics.allShapes()
  return Constants.ECONOMY.cosmetics.shapes
end

function Cosmetics.isColorUnlocked(id)
  local s = ensure()
  return s.unlockedColorSet[id] or false
end

function Cosmetics.isShapeUnlocked(id)
  local s = ensure()
  return s.unlockedShapeSet[id] or false
end

-- Economy integration functions
function Cosmetics.purchaseColor(colorId)
  local Economy = require("src.systems.economy")
  local s = ensure()
  
  if s.unlockedColorSet[colorId] then
    return false, "Already unlocked"
  end
  
  local color = Constants.ECONOMY.cosmetics.colors[colorId]
  if not color then
    return false, "Invalid color"
  end
  
  if Economy.spendCredits(color.cost) then
    table.insert(s.unlockedColors, colorId)
    s.unlockedColorSet[colorId] = true
    Banner.trigger("Purchased: " .. color.name)
    persist()
    return true, "Color purchased!"
  else
    return false, "Not enough credits"
  end
end

function Cosmetics.purchaseShape(shapeId)
  local Economy = require("src.systems.economy")
  local s = ensure()
  
  if s.unlockedShapeSet[shapeId] then
    return false, "Already unlocked"
  end
  
  local shape = Constants.ECONOMY.cosmetics.shapes[shapeId]
  if not shape then
    return false, "Invalid shape"
  end
  
  if Economy.spendCredits(shape.cost) then
    table.insert(s.unlockedShapes, shapeId)
    s.unlockedShapeSet[shapeId] = true
    Banner.trigger("Purchased: " .. shape.name)
    persist()
    return true, "Shape purchased!"
  else
    return false, "Not enough credits"
  end
end

function Cosmetics.selectColor(colorId)
  local s = ensure()
  if s.unlockedColorSet[colorId] or colorId == nil then
    s.selectedColor = colorId
    persist()
    return true
  end
  return false
end

function Cosmetics.selectShape(shapeId)
  local s = ensure()
  if s.unlockedShapeSet[shapeId] then
    s.selectedShape = shapeId
    persist()
    return true
  end
  return false
end

function Cosmetics.getSelectedColor()
  local s = ensure()
  return s.selectedColor
end

function Cosmetics.getSelectedShape()
  local s = ensure()
  return s.selectedShape
end

function Cosmetics.getColor()
  local colorId = Cosmetics.getSelectedColor()
  if not colorId then
    -- no color selected: white
    return {1,1,1,1}
  end
  
  if colorId == 'rgb_trip' then
    local time = love.timer.getTime()
    return rgbTripColor(time)
  end
  
  local color = Constants.ECONOMY.cosmetics.colors[colorId]
  if color then
    return color.color
  end
  
  -- fallback to white
  return {1,1,1,1}
end

function Cosmetics.drawShip(x, y, width, height)
  local shapeId = Cosmetics.getSelectedShape()
  local drawer = shapeDrawers[shapeId] or shapeDrawers.triangle
  drawer(x, y, width, height)
end

function Cosmetics.drawSpecificShape(shapeId, x, y, width, height)
  local drawer = shapeDrawers[shapeId] or shapeDrawers.triangle
  drawer(x, y, width, height)
end

-- Force reset cosmetics to defaults (used by settings clear data)
function Cosmetics.reset()
  state = nil
  -- Also delete the save file to prevent reloading
  local Save = require("src.systems.save")
  if love.filesystem.getInfo(FILENAME) then
    love.filesystem.remove(FILENAME)
  end
end

return Cosmetics
