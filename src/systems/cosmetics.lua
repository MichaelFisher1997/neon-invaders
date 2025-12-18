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

-- Shared helpers for ship silhouettes
local function clampColor(value)
  if value < 0 then return 0 end
  if value > 1 then return 1 end
  return value
end

local function withColorOffset(delta, drawFn)
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(
    clampColor(r + delta),
    clampColor(g + delta),
    clampColor(b + delta),
    a
  )
  drawFn()
  love.graphics.setColor(r, g, b, a)
end

local function computeVerticalStretch(width, height)
  if height <= 0 then return 1 end
  local aspect = width / height
  if aspect > 1 then
    return math.min(1.8, math.pow(aspect, 0.55))
  end
  return math.max(0.75, math.pow(aspect, 0.55))
end

-- Helper for Neon Ship Rendering
local function drawNeonPoly(points, x, y, width, height, brightnessOffset)
  local halfW = width / 2
  local halfH = height / 2
  local stretch = computeVerticalStretch(width, height)
  halfH = halfH * stretch
  
  -- Transform vertices
  local vertices = {}
  for _, point in ipairs(points) do
    table.insert(vertices, x + point[1] * halfW)
    table.insert(vertices, y + point[2] * halfH)
  end
  
  local r, g, b, a = love.graphics.getColor()
  
  -- 1. Glass Fill (Transparent)
  love.graphics.setColor(r, g, b, a * 0.15)
  love.graphics.polygon("fill", vertices)
  
  -- 2. Neon Glow Stroke (Wider, semi-transparent)
  love.graphics.setColor(r, g, b, a * 0.4)
  love.graphics.setLineWidth(3)
  love.graphics.setLineJoin('miter')
  love.graphics.polygon("line", vertices)
  
  -- 3. Core Bright Stroke (Sharp, opaque)
  local br = 1.0 - (brightnessOffset or 0) -- Adjust brightness if needed
  love.graphics.setColor(r*br, g*br, b*br, a)
  love.graphics.setLineWidth(1.5)
  love.graphics.polygon("line", vertices)
  
  -- 4. Vertex Highlights (Bright dots)
  love.graphics.setColor(1, 1, 1, a * 0.8)
  love.graphics.setPointSize(2)
  for i=1, #vertices, 2 do
    love.graphics.points(vertices[i], vertices[i+1])
  end
  
  love.graphics.setLineWidth(1)
  -- Reset color
  love.graphics.setColor(r, g, b, a)
end

-- Prebuilt silhouettes use normalized coordinates in the range [-1, 1]
local TRIANGLE_HULL = {
  {0.0, -1.0},
  {0.36, -0.25},
  {0.22, 0.15},
  {0.18, 0.6},
  {0.08, 1.0},
  {-0.08, 1.0},
  {-0.18, 0.6},
  {-0.22, 0.15},
  {-0.36, -0.25},
}

local TRIANGLE_COCKPIT = {
  {0.0, -0.85},
  {0.14, -0.2},
  {0.1, 0.4},
  {0.0, 0.15},
  {-0.1, 0.4},
  {-0.14, -0.2},
}

local TRIANGLE_THRUSTER = {
  {0.0, 1.0},
  {0.12, 0.72},
  {0.0, 0.86},
  {-0.12, 0.72},
}

local DIAMOND_HULL = {
  {0.0, -1.0},
  {0.28, -0.55},
  {0.52, -0.15},
  {0.48, 0.28},
  {0.24, 1.0},
  {-0.24, 1.0},
  {-0.48, 0.28},
  {-0.52, -0.15},
  {-0.28, -0.55},
}

local DIAMOND_COCKPIT = {
  {0.0, -0.78},
  {0.16, -0.35},
  {0.12, 0.28},
  {0.0, 0.08},
  {-0.12, 0.28},
  {-0.16, -0.35},
}

local DIAMOND_ENGINES = {
  {0.2, 1.0},
  {0.34, 0.62},
  {0.18, 0.7},
  {0.1, 0.94},
  {-0.1, 0.94},
  {-0.18, 0.7},
  {-0.34, 0.62},
  {-0.2, 1.0},
}

local HEXAGON_HULL = {
  {0.0, -1.0},
  {0.42, -0.7},
  {0.76, -0.26},
  {0.6, 0.45},
  {0.28, 1.0},
  {-0.28, 1.0},
  {-0.6, 0.45},
  {-0.76, -0.26},
  {-0.42, -0.7},
}

local HEXAGON_SPINE = {
  {0.0, -0.92},
  {0.2, -0.5},
  {0.18, 0.42},
  {0.0, 0.18},
  {-0.18, 0.42},
  {-0.2, -0.5},
}

local HEXAGON_SHIELDS = {
  {0.6, -0.28},
  {0.76, -0.1},
  {0.64, 0.36},
  {0.48, 0.46},
  {0.32, -0.08},
}

local ARROW_HULL = {
  {0.0, -1.0},
  {0.22, -0.65},
  {0.6, -0.3},
  {0.38, -0.08},
  {0.34, 0.42},
  {0.14, 1.0},
  {-0.14, 1.0},
  {-0.34, 0.42},
  {-0.38, -0.08},
  {-0.6, -0.3},
  {-0.22, -0.65},
}

local ARROW_COCKPIT = {
  {0.0, -0.78},
  {0.16, -0.38},
  {0.12, 0.18},
  {0.0, -0.02},
  {-0.12, 0.18},
  {-0.16, -0.38},
}

local ARROW_TAIL = {
  {0.0, 1.0},
  {0.18, 0.68},
  {0.0, 0.76},
  {-0.18, 0.68},
}

local STAR_HULL = {
  {0.0, -1.0},
  {0.2, -0.45},
  {0.64, -0.48},
  {0.32, -0.05},
  {0.58, 0.6},
  {0.0, 0.22},
  {-0.58, 0.6},
  {-0.32, -0.05},
  {-0.64, -0.48},
  {-0.2, -0.45},
}

local STAR_CORE = {
  {0.0, -0.65},
  {0.22, -0.28},
  {0.16, 0.2},
  {0.0, 0.02},
  {-0.16, 0.2},
  {-0.22, -0.28},
}

local function drawTriangleShip(x, y, width, height)
  drawNeonPoly(TRIANGLE_HULL, x, y, width, height)
  
  -- Bright Cockpit
  love.graphics.setColor(1, 1, 1, 0.8)
  drawNeonPoly(TRIANGLE_COCKPIT, x, y, width * 0.5, height * 0.6)
  
  -- Thruster Glow
  local flicker = math.sin(love.timer.getTime() * 20) * 0.2 + 0.8
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(r, g, b, a * flicker)
  drawNeonPoly(TRIANGLE_THRUSTER, x, y, width * 0.6, height)
end

local function drawDiamondShip(x, y, width, height)
  drawNeonPoly(DIAMOND_HULL, x, y, width, height)
  
  -- Inner Core
  love.graphics.setColor(1, 1, 1, 0.9)
  drawNeonPoly(DIAMOND_COCKPIT, x, y, width * 0.5, height * 0.6)
  
  -- Engine Accents
  drawNeonPoly(DIAMOND_ENGINES, x, y, width * 0.8, height)
end

local function drawHexagonShip(x, y, width, height)
  drawNeonPoly(HEXAGON_HULL, x, y, width, height)
  
  -- Shields (Side plating)
  drawNeonPoly(HEXAGON_SHIELDS, x, y, width, height)
  local mirrored = {}
  for i = #HEXAGON_SHIELDS, 1, -1 do
    local point = HEXAGON_SHIELDS[i]
    table.insert(mirrored, { -point[1], point[2] })
  end
  drawNeonPoly(mirrored, x, y, width, height)
  
  -- Central Spine (Darker/Sleek)
  drawNeonPoly(HEXAGON_SPINE, x, y, width * 0.65, height * 0.85)
end

local function drawArrowShip(x, y, width, height)
  drawNeonPoly(ARROW_HULL, x, y, width, height)
  
  -- Sharp Cockpit
  love.graphics.setColor(1, 1, 1, 0.9)
  drawNeonPoly(ARROW_COCKPIT, x, y, width * 0.6, height * 0.65)
  
  -- Split Tail
  drawNeonPoly(ARROW_TAIL, x, y, width * 0.75, height)
end

local function drawCircleShip(x, y, width, height)
  local stretch = computeVerticalStretch(width, height)
  local baseRadius = width * 0.25
  local tallRadius = baseRadius * stretch * 0.9
  local shortRadius = math.min(height / 2, tallRadius)
  
  local r, g, b, a = love.graphics.getColor()
  
  -- 1. Glass Orbit
  love.graphics.setColor(r, g, b, a * 0.15)
  love.graphics.ellipse("fill", x, y, baseRadius, shortRadius)
  
  -- 2. Neon Ring
  love.graphics.setColor(r, g, b, a * 0.8)
  love.graphics.setLineWidth(2.5)
  love.graphics.ellipse("line", x, y, baseRadius, shortRadius)
  
  -- 3. Side Pods (Neon)
  local podOffsetX = baseRadius * 1.15
  love.graphics.circle("fill", x - podOffsetX, y + shortRadius * 0.1, baseRadius * 0.25)
  love.graphics.circle("fill", x + podOffsetX, y + shortRadius * 0.1, baseRadius * 0.25)
  
  love.graphics.setColor(1, 1, 1, a)
  love.graphics.circle("fill", x - podOffsetX, y + shortRadius * 0.1, baseRadius * 0.1)
  love.graphics.circle("fill", x + podOffsetX, y + shortRadius * 0.1, baseRadius * 0.1)
  
  -- 4. Central Core
  love.graphics.setColor(r, g, b, a * 0.3)
  love.graphics.ellipse("fill", x, y, baseRadius * 0.5, shortRadius * 0.5)
  love.graphics.setColor(1, 1, 1, a)
  love.graphics.circle("fill", x, y, baseRadius * 0.15)
  
  love.graphics.setLineWidth(1)
end

local function drawStarShip(x, y, width, height)
  drawNeonPoly(STAR_HULL, x, y, width, height)
  
  -- Burning Core
  local flicker = math.sin(love.timer.getTime() * 10) * 0.2 + 0.8
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(r, g, b, a * flicker)
  drawNeonPoly(STAR_CORE, x, y, width * 0.6, height * 0.7)
  
  -- Wings
  local wing = {
    {0.54, 0.12},
    {0.76, 0.32},
    {0.52, 0.48},
    {0.32, 0.18},
  }
  drawNeonPoly(wing, x, y, width, height)
  local mirrored = {}
  for i = #wing, 1, -1 do
    local point = wing[i]
    table.insert(mirrored, { -point[1], point[2] })
  end
  drawNeonPoly(mirrored, x, y, width, height)
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
