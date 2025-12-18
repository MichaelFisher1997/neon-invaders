local Neon = {}
local Fonts = require("src.ui.fonts")

-- Neon Palette
Neon.COLORS = {
  cyan = {0.153, 0.953, 1.0},
  magenta = {1.0, 0.182, 0.651},
  white = {1.0, 1.0, 1.0},
  dark = {0.05, 0.05, 0.1},
  red = {1.0, 0.2, 0.2},
  blue = {0.2, 0.4, 1.0},
  green = {0.2, 1.0, 0.4},
  gold = {1.0, 0.84, 0.0},
  purple = {0.6, 0.2, 1.0}
}

function Neon.drawGlowText(text, x, y, font, color, glowColor, scale, align, limit)
  scale = scale or 1.0
  align = align or 'left'
  limit = limit or 10000
  love.graphics.setFont(font)
  
  -- Glow layers
  local oldR, oldG, oldB, oldA = love.graphics.getColor()
  local r, g, b = unpack(glowColor or Neon.COLORS.cyan)
  
  -- Outer glow
  love.graphics.setColor(r, g, b, 0.2)
  for i = 1, 3 do
    local off = i * 2 * scale
    love.graphics.printf(text, x + off, y + off, limit, align, 0, scale, scale)
    love.graphics.printf(text, x - off, y - off, limit, align, 0, scale, scale)
    love.graphics.printf(text, x + off, y - off, limit, align, 0, scale, scale)
    love.graphics.printf(text, x - off, y + off, limit, align, 0, scale, scale)
  end
  
  -- Inner core
  love.graphics.setColor(color or Neon.COLORS.white)
  love.graphics.printf(text, x, y, limit, align, 0, scale, scale)
  
  love.graphics.setColor(oldR, oldG, oldB, oldA)
end

function Neon.drawButton(text, rect, isSelected, color)
  local baseColor = color or Neon.COLORS.cyan
  local r, g, b = unpack(baseColor)
  local timer = love.timer.getTime()
  
  local alpha = isSelected and 1.0 or 0.6
  
  -- Background (if selected)
  if isSelected then
    love.graphics.setColor(r, g, b, 0.1)
    love.graphics.rectangle('fill', rect.x, rect.y, rect.w, rect.h, 12, 12)
    
    -- Pulse border
    local pulse = (math.sin(timer * 5) + 1) * 0.5 * 4
    love.graphics.setColor(r, g, b, 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle('line', rect.x - pulse, rect.y - pulse, rect.w + pulse*2, rect.h + pulse*2, 12 + pulse, 12 + pulse)
  end
  
  -- Main Border
  love.graphics.setColor(r, g, b, alpha)
  love.graphics.setLineWidth(isSelected and 3 or 1)
  love.graphics.rectangle('line', rect.x, rect.y, rect.w, rect.h, 12, 12)
  love.graphics.setLineWidth(1)
  
  -- Text
  love.graphics.setFont(Fonts.get(24))
  local th = love.graphics.getFont():getHeight()
  
  -- Selection marker
  if isSelected then
    local arrowOff = 10 + math.sin(timer * 8) * 5
    love.graphics.print(">", rect.x + 20 + arrowOff, rect.y + rect.h/2 - th/2)
  end
  
  -- Button Text
  love.graphics.setColor(r, g, b, alpha + 0.2)
  love.graphics.printf(text, rect.x, rect.y + rect.h/2 - th/2, rect.w, 'center')
end

return Neon
