local Scaling = {}

local VIRTUAL_WIDTH = 1280
local VIRTUAL_HEIGHT = 720

local canvas
local scaleX, scaleY, scaleUniform
local offsetX, offsetY

local function recomputeScale(windowWidth, windowHeight)
  scaleX = windowWidth / VIRTUAL_WIDTH
  scaleY = windowHeight / VIRTUAL_HEIGHT
  scaleUniform = math.min(scaleX, scaleY)
  local drawWidth = VIRTUAL_WIDTH * scaleUniform
  local drawHeight = VIRTUAL_HEIGHT * scaleUniform
  offsetX = math.floor((windowWidth - drawWidth) / 2 + 0.5)
  offsetY = math.floor((windowHeight - drawHeight) / 2 + 0.5)
end

function Scaling.getVirtualSize()
  return VIRTUAL_WIDTH, VIRTUAL_HEIGHT
end

function Scaling.getCanvas()
  return canvas
end

function Scaling.getScale()
  return scaleUniform, offsetX, offsetY
end

function Scaling.toVirtual(x, y)
  local mx = (x - offsetX) / scaleUniform
  local my = (y - offsetY) / scaleUniform
  return mx, my
end

function Scaling.toScreen(x, y)
  local sx = x * scaleUniform + offsetX
  local sy = y * scaleUniform + offsetY
  return sx, sy
end

function Scaling.resize(windowWidth, windowHeight)
  recomputeScale(windowWidth, windowHeight)
end

function Scaling.setup()
  love.graphics.setDefaultFilter("nearest", "nearest", 1)
  canvas = love.graphics.newCanvas(VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
  local w, h = love.graphics.getDimensions()
  recomputeScale(w, h)
end

function Scaling.begin()
  love.graphics.push("all")
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0.04, 0.04, 0.06, 1.0) -- background near-black
end

function Scaling.finish()
  love.graphics.setCanvas()
  love.graphics.clear(0, 0, 0, 1)

  -- draw letterbox background (already black)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(canvas, offsetX, offsetY, 0, scaleUniform, scaleUniform)
  love.graphics.pop()
end

-- Panels in virtual coordinates: left 20%, center 60%, right 20%
function Scaling.getPanelsVirtual()
  local lw = math.floor(VIRTUAL_WIDTH * 0.20 + 0.5)
  local cw = math.floor(VIRTUAL_WIDTH * 0.60 + 0.5)
  local rw = VIRTUAL_WIDTH - lw - cw
  local h = VIRTUAL_HEIGHT
  local left = { x = 0, y = 0, w = lw, h = h }
  local center = { x = lw, y = 0, w = cw, h = h }
  local right = { x = lw + cw, y = 0, w = rw, h = h }
  return left, center, right
end

function Scaling.pushViewport(rect)
  love.graphics.push()
  love.graphics.setScissor(rect.x, rect.y, rect.w, rect.h)
  love.graphics.translate(rect.x, rect.y)
end

function Scaling.popViewport()
  love.graphics.setScissor()
  love.graphics.pop()
end

return Scaling
