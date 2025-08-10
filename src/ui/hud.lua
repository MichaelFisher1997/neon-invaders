local HUD = {}
local Input = require("src.core.input")

local COLORS = {
  cyan = {0.153, 0.953, 1.0},
  magenta = {1.0, 0.182, 0.651},
  purple = {0.541, 0.169, 0.886},
  white = {1.0, 1.0, 1.0},
}

local function setColorA(c, a)
  love.graphics.setColor(c[1], c[2], c[3], a)
end

local function glowRect(x, y, w, h, r, color)
  for i = 1, 3 do
    local grow = i * 3
    setColorA(color, 0.10 / i)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle('line', x - grow, y - grow, w + grow * 2, h + grow * 2, r + grow, r + grow)
  end
  love.graphics.setLineWidth(1)
end

local function glowCircle(cx, cy, r, color)
  for i = 1, 4 do
    local rr = r + i * 3
    setColorA(color, 0.08 / i)
    love.graphics.setLineWidth(2)
    love.graphics.circle('line', cx, cy, rr)
  end
  love.graphics.setLineWidth(1)
end

local function textShadowPrint(text, x, y)
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.print(text, x+2, y+2)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(text, x, y)
end

function HUD.draw(score, lives, wave, vw, vh)
  love.graphics.setFont(love.graphics.newFont(18))
  -- Score top-left
  textShadowPrint("Score: " .. tostring(score), vw * 0.02, vh * 0.02)
  -- Wave top-right
  local waveText = "Wave " .. tostring(wave)
  local tw = love.graphics.getFont():getWidth(waveText)
  textShadowPrint(waveText, vw - tw - vw*0.02, vh * 0.02)
  -- Lives centered top as triangles
  local centerX = vw / 2
  local y = vh * 0.04
  local spacing = 32
  love.graphics.setColor(0.153, 0.953, 1.0, 1.0)
  for i = 1, lives do
    local x = centerX + (i - (lives+1)/2) * spacing
    love.graphics.polygon("fill", x, y, x-10, y+16, x+10, y+16)
  end
end

function HUD.drawLeftControls(vw, vh)
  -- Movement pad (left/right) combined into a single wide pad at bottom-left
  local gap = math.floor(vw * 0.06 + 0.5)
  local padW = vw - gap * 2
  local padH = math.floor(vh * 0.22 + 0.5)
  local x = gap
  local y = vh - padH - gap
  local held = Input.getHeld()

  -- Base
  setColorA(COLORS.white, 0.08)
  love.graphics.rectangle('fill', x, y, padW, padH, 12, 12)
  setColorA(COLORS.white, 0.22)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle('line', x, y, padW, padH, 12, 12)
  glowRect(x, y, padW, padH, 12, COLORS.cyan)

  -- Pressed halves highlight
  if held.left then
    setColorA(COLORS.cyan, 0.18)
    love.graphics.rectangle('fill', x + 4, y + 4, padW/2 - 8, padH - 8, 10, 10)
  end
  if held.right then
    setColorA(COLORS.cyan, 0.18)
    love.graphics.rectangle('fill', x + padW/2 + 4, y + 4, padW/2 - 8, padH - 8, 10, 10)
  end

  -- divider
  setColorA(COLORS.white, 0.20)
  love.graphics.line(x + padW/2, y + 8, x + padW/2, y + padH - 8)
  love.graphics.setLineWidth(1)

  -- Arrows
  setColorA(COLORS.white, held.left and 0.9 or 0.55)
  local function arrowLeft(ax, ay, w, h)
    love.graphics.polygon('fill', ax + w*0.66, ay + h*0.30, ax + w*0.36, ay + h*0.50, ax + w*0.66, ay + h*0.70)
  end
  local function arrowRight(ax, ay, w, h)
    love.graphics.polygon('fill', ax + w*0.34, ay + h*0.30, ax + w*0.64, ay + h*0.50, ax + w*0.34, ay + h*0.70)
  end
  arrowLeft(x + 4, y + 4, padW/2 - 8, padH - 8)
  setColorA(COLORS.white, held.right and 0.9 or 0.55)
  arrowRight(x + padW/2 + 4, y + 4, padW/2 - 8, padH - 8)

  -- Label
  setColorA(COLORS.cyan, 0.85)
  love.graphics.setFont(love.graphics.newFont(14))
  local label = 'MOVE'
  local tw = love.graphics.getFont():getWidth(label)
  love.graphics.print(label, x + (padW - tw)/2, y - 18)
end

function HUD.drawRightControls(vw, vh)
  -- Hold-to-fire circle on the right panel
  local gap = math.floor(vw * 0.06 + 0.5)
  local fireR = math.max(22, math.floor(vw * 0.18 + 0.5))
  local cx = vw - fireR - gap
  local cy = vh - fireR - gap
  local held = Input.getHeld()
  local rr = held.fire and math.floor(fireR * 1.05 + 0.5) or fireR

  -- Base
  setColorA(COLORS.white, 0.08)
  love.graphics.circle('fill', cx, cy, rr)
  setColorA(COLORS.white, 0.26)
  love.graphics.setLineWidth(2)
  love.graphics.circle('line', cx, cy, rr)
  glowCircle(cx, cy, rr, COLORS.magenta)

  -- Pressed fill
  if held.fire then
    setColorA(COLORS.magenta, 0.20)
    love.graphics.circle('fill', cx, cy, rr - 3)
  end

  -- Simple "bullet" triangle icon
  setColorA(COLORS.white, held.fire and 0.95 or 0.70)
  love.graphics.polygon('fill', cx, cy - rr*0.28, cx - rr*0.16, cy + rr*0.12, cx + rr*0.16, cy + rr*0.12)
  love.graphics.setLineWidth(1)

  -- label
  setColorA(COLORS.magenta, 0.85)
  love.graphics.setFont(love.graphics.newFont(14))
  local label = 'HOLD TO FIRE'
  local tw = love.graphics.getFont():getWidth(label)
  love.graphics.print(label, cx - tw / 2, cy - fireR - 18)
end

function HUD.drawPanelFrame(vw, vh)
  love.graphics.setColor(1,1,1,0.06)
  love.graphics.rectangle('fill', 0, 0, vw, vh)
  love.graphics.setColor(1,1,1,0.18)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle('line', 2, 2, vw-4, vh-4, 8, 8)
  love.graphics.setLineWidth(1)
end

return HUD
