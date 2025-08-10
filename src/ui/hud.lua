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
  local held = Input.getHeld()
  -- Entire panel: MOVE LEFT
  -- Base overlay
  setColorA(COLORS.white, held.left and 0.20 or 0.08)
  love.graphics.rectangle('fill', 0, 0, vw, vh)
  -- Big left arrow centered
  local ax, ay, aw, ah = vw*0.10, vh*0.25, vw*0.80, vh*0.50
  setColorA(COLORS.white, held.left and 0.95 or 0.70)
  love.graphics.polygon('fill', ax + aw*0.66, ay + ah*0.30, ax + aw*0.36, ay + ah*0.50, ax + aw*0.66, ay + ah*0.70)
  -- Label
  setColorA(COLORS.cyan, 0.85)
  love.graphics.setFont(love.graphics.newFont(16))
  local label = 'MOVE LEFT'
  local tw = love.graphics.getFont():getWidth(label)
  love.graphics.print(label, (vw - tw)/2, vh*0.06)
end

function HUD.drawRightControls(vw, vh)
  local held = Input.getHeld()
  -- Entire panel: MOVE RIGHT
  setColorA(COLORS.white, held.right and 0.20 or 0.08)
  love.graphics.rectangle('fill', 0, 0, vw, vh)
  -- Big right arrow centered
  local ax, ay, aw, ah = vw*0.10, vh*0.25, vw*0.80, vh*0.50
  setColorA(COLORS.white, held.right and 0.95 or 0.70)
  love.graphics.polygon('fill', ax + aw*0.34, ay + ah*0.30, ax + aw*0.64, ay + ah*0.50, ax + aw*0.34, ay + ah*0.70)
  -- Label
  setColorA(COLORS.magenta, 0.85)
  love.graphics.setFont(love.graphics.newFont(16))
  local label = 'MOVE RIGHT'
  local tw = love.graphics.getFont():getWidth(label)
  love.graphics.print(label, (vw - tw)/2, vh*0.06)
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
