local HUD = {}
local Input = require("src.core.input")

local COLORS = {
  cyan = {0.153, 0.953, 1.0},
  magenta = {1.0, 0.182, 0.651},
  purple = {0.541, 0.169, 0.886},
  white = {1.0, 1.0, 1.0},
}

-- HSV to RGB conversion for wave color
local function hsvToRgb(h, s, v)
  local r, g, b
  local i = math.floor(h * 6)
  local f = h * 6 - i
  local p = v * (1 - s)
  local q = v * (1 - f * s)
  local t = v * (1 - (1 - f) * s)
  i = i % 6
  if i == 0 then r, g, b = v, t, p
  elseif i == 1 then r, g, b = q, v, p
  elseif i == 2 then r, g, b = p, v, t
  elseif i == 3 then r, g, b = p, q, v
  elseif i == 4 then r, g, b = t, p, v
  elseif i == 5 then r, g, b = v, p, q
  end
  return r, g, b
end

-- Get color for a specific wave number
local function getWaveColor(wave)
  -- Each wave gets a different hue in the rainbow
  -- Spread colors evenly across the spectrum
  local hue = ((wave - 1) * 0.1) % 1.0  -- 10% hue shift per wave
  return hsvToRgb(hue, 0.85, 1.0)
end

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
  local Economy = require("src.systems.economy")
  local credits = Economy.getCredits()
  local Boss = require("src.game.boss")
  local hasBoss = Boss.exists()
  
  -- CLEAN 4-SECTION HUD
  local panelH = 60  -- Fixed height, boss bar goes below
  local sectionW = vw / 4
  
  -- Dark background
  love.graphics.setColor(0.02, 0.02, 0.05, 0.95)
  love.graphics.rectangle("fill", 0, 0, vw, panelH)
  
  -- Bottom glow line
  if hasBoss then
    love.graphics.setColor(1.0, 0.182, 0.651, 0.8)
  else
    love.graphics.setColor(0.153, 0.953, 1.0, 0.7)
  end
  love.graphics.setLineWidth(3)
  love.graphics.line(0, panelH - 2, vw, panelH - 2)
  love.graphics.setLineWidth(1)
  
  -- Vertical separators between sections
  love.graphics.setColor(0.153, 0.953, 1.0, 0.15)
  love.graphics.setLineWidth(1)
  for i = 1, 3 do
    local x = sectionW * i
    love.graphics.line(x, 8, x, panelH - 8)
  end
  love.graphics.setLineWidth(1)
  
  local labelFont = love.graphics.newFont(11)
  local valueFont = love.graphics.newFont(24)
  local padding = 12
  
  -- ===== SECTION 1: SCORE (with RGB glow effect) =====
  local s1X = padding
  
  love.graphics.setFont(labelFont)
  love.graphics.setColor(0.153, 0.953, 1.0, 0.85)
  love.graphics.print("SCORE", s1X, 10)
  
  love.graphics.setFont(valueFont)
  local scoreText = tostring(score)
  
  -- RGB glow effect - MUCH MORE VISIBLE
  -- Outer glow layer (large offset)
  love.graphics.setColor(1, 0, 0, 0.7)
  love.graphics.print(scoreText, s1X - 3, 24)
  love.graphics.print(scoreText, s1X - 4, 24)
  
  love.graphics.setColor(0, 1, 0, 0.7)
  love.graphics.print(scoreText, s1X + 3, 24)
  love.graphics.print(scoreText, s1X + 4, 24)
  
  love.graphics.setColor(0, 0, 1, 0.7)
  love.graphics.print(scoreText, s1X, 24 - 3)
  love.graphics.print(scoreText, s1X, 24 - 4)
  
  love.graphics.setColor(1, 1, 0, 0.7)
  love.graphics.print(scoreText, s1X, 24 + 3)
  love.graphics.print(scoreText, s1X, 24 + 4)
  
  -- Inner glow layer (medium offset)
  love.graphics.setColor(1, 0, 1, 0.8)
  love.graphics.print(scoreText, s1X - 2, 24 - 2)
  
  love.graphics.setColor(0, 1, 1, 0.8)
  love.graphics.print(scoreText, s1X + 2, 24 + 2)
  
  -- Shadow (dark)
  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.print(scoreText, s1X + 1, 24 + 1)
  
  -- Base bright white (neon core)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(scoreText, s1X, 24)
  
  -- ===== SECTION 2: CREDITS (same gold color) =====
  local s2X = sectionW + padding
  
  -- Use exact same gold color for both label and number
  local goldR, goldG, goldB = 1.0, 0.75, 0.1
  
  love.graphics.setFont(labelFont)
  love.graphics.setColor(goldR, goldG, goldB, 1)
  love.graphics.print("CREDITS", s2X, 10)
  
  love.graphics.setFont(valueFont)
  local creditsText = tostring(credits)
  
  -- Just use the same gold - no shine, perfectly matching
  love.graphics.setColor(goldR, goldG, goldB, 1)
  love.graphics.print(creditsText, s2X, 24)
  
  -- ===== SECTION 3: LIVES (turns red at 1) =====
  local s3X = sectionW * 2 + padding
  
  -- Color changes based on lives
  local livesColor = {0.153, 0.953, 1.0}  -- Default cyan
  if lives == 1 then
    livesColor = {1.0, 0.2, 0.2}  -- Red when critical
  end
  
  love.graphics.setFont(labelFont)
  love.graphics.setColor(livesColor[1], livesColor[2], livesColor[3], 0.85)
  love.graphics.print("LIVES", s3X, 10)
  
  -- Lives as number (like other stats)
  love.graphics.setFont(valueFont)
  love.graphics.setColor(livesColor[1], livesColor[2], livesColor[3], 1.0)
  love.graphics.print(tostring(lives), s3X, 24)
  
  -- ===== SECTION 4: WAVE (color changes per wave) =====
  local s4X = sectionW * 3 + padding
  
  love.graphics.setFont(labelFont)
  love.graphics.setColor(0.153, 0.953, 1.0, 0.85)
  love.graphics.print("WAVE", s4X, 10)
  
  -- Wave number with color based on wave number
  love.graphics.setFont(valueFont)
  local r, g, b = getWaveColor(wave)
  love.graphics.setColor(r, g, b, 1)
  love.graphics.print(tostring(wave), s4X, 24)
  
  -- Boss health bar (if boss exists)
  HUD.drawBossHealth(vw, panelH)
end

function HUD.drawBossHealth(vw, panelH)
  local Boss = require("src.game.boss")
  if Boss.exists() then
    local BossBase = require("src.game.boss.base")
    BossBase.drawHealthBar(vw, panelH)
  end
end

function HUD.drawLeftControls(vw, vh)
  local held = Input.getHeld()
  local swipeDir = Input.getSwipeDirection()
  -- Entire panel: MOVE LEFT
  -- Base overlay
  setColorA(COLORS.white, held.left and 0.20 or 0.08)
  love.graphics.rectangle('fill', 0, 0, vw, vh)
  -- Big left arrow centered
  local ax, ay, aw, ah = vw*0.10, vh*0.25, vw*0.80, vh*0.50
  setColorA(COLORS.white, held.left and 0.95 or 0.70)
  love.graphics.polygon('fill', ax + aw*0.66, ay + ah*0.30, ax + aw*0.36, ay + ah*0.50, ax + aw*0.66, ay + ah*0.70)
  
  -- Swipe indicator
  if swipeDir then
    setColorA(COLORS.cyan, 0.6)
    local swipeY = vh * 0.75
    local swipeCX = vw / 2
    if swipeDir == "left" then
      -- Left arrow
      love.graphics.polygon('fill', swipeCX + 20, swipeY, swipeCX - 10, swipeY - 10, swipeCX - 10, swipeY + 10)
    else
      -- Right arrow
      love.graphics.polygon('fill', swipeCX - 20, swipeY, swipeCX + 10, swipeY - 10, swipeCX + 10, swipeY + 10)
    end
    love.graphics.setFont(love.graphics.newFont(14))
    local swipeText = swipeDir == "left" and "SWIPE LEFT" or "SWIPE RIGHT"
    local tw = love.graphics.getFont():getWidth(swipeText)
    love.graphics.print(swipeText, (vw - tw)/2, swipeY + 20)
  end
  
  -- Label
  setColorA(COLORS.cyan, 0.85)
  love.graphics.setFont(love.graphics.newFont(16))
  local label = 'MOVE LEFT'
  local tw = love.graphics.getFont():getWidth(label)
  love.graphics.print(label, (vw - tw)/2, vh*0.06)
end

function HUD.drawRightControls(vw, vh)
  local held = Input.getHeld()
  local swipeDir = Input.getSwipeDirection()
  -- Entire panel: MOVE RIGHT
  setColorA(COLORS.white, held.right and 0.20 or 0.08)
  love.graphics.rectangle('fill', 0, 0, vw, vh)
  -- Big right arrow centered
  local ax, ay, aw, ah = vw*0.10, vh*0.25, vw*0.80, vh*0.50
  setColorA(COLORS.white, held.right and 0.95 or 0.70)
  love.graphics.polygon('fill', ax + aw*0.34, ay + ah*0.30, ax + aw*0.64, ay + ah*0.50, ax + aw*0.34, ay + ah*0.70)
  
  -- Swipe indicator
  if swipeDir then
    setColorA(COLORS.magenta, 0.6)
    local swipeY = vh * 0.75
    local swipeCX = vw / 2
    if swipeDir == "left" then
      -- Left arrow
      love.graphics.polygon('fill', swipeCX + 20, swipeY, swipeCX - 10, swipeY - 10, swipeCX - 10, swipeY + 10)
    else
      -- Right arrow
      love.graphics.polygon('fill', swipeCX - 20, swipeY, swipeCX + 10, swipeY - 10, swipeCX + 10, swipeY + 10)
    end
    love.graphics.setFont(love.graphics.newFont(14))
    local swipeText = swipeDir == "left" and "SWIPE LEFT" or "SWIPE RIGHT"
    local tw = love.graphics.getFont():getWidth(swipeText)
    love.graphics.print(swipeText, (vw - tw)/2, swipeY + 20)
  end
  
  -- Label
  setColorA(COLORS.magenta, 0.85)
  love.graphics.setFont(love.graphics.newFont(16))
  local label = 'MOVE RIGHT'
  local tw = love.graphics.getFont():getWidth(label)
  love.graphics.print(label, (vw - tw)/2, vh*0.06)
end

-- Legacy function - credits now drawn in main HUD
function HUD.drawCredits(vw, vh, hudPanelHeight)
  -- Deprecated - credits integrated into main HUD
end

-- Compact events display in HUD
function HUD.drawEventsCompact(vw, vh, startX, startY)
  local Events = require("src.game.events")
  local activeEvents = Events.getActiveEvents()
  
  if #activeEvents == 0 then return end
  
  local barWidth = 100
  local barHeight = 6
  
  love.graphics.setFont(love.graphics.newFont(9))
  
  -- Only show first active event in compact mode
  local event = activeEvents[1]
  
  -- Event name (abbreviated if needed)
  local eventName = event.name
  if #eventName > 15 then
    eventName = eventName:sub(1, 12) .. "..."
  end
  
  love.graphics.setColor(event.color[1], event.color[2], event.color[3], 0.9)
  love.graphics.print(eventName, startX, startY - 10)
  
  -- Duration bar background
  love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
  love.graphics.rectangle('fill', startX, startY, barWidth, barHeight, 2, 2)
  
  -- Duration bar fill
  local fillWidth = barWidth * (event.timeRemaining / event.duration)
  love.graphics.setColor(event.color[1], event.color[2], event.color[3], 0.9)
  love.graphics.rectangle('fill', startX, startY, fillWidth, barHeight, 2, 2)
  
  -- Duration bar border
  love.graphics.setColor(event.color[1], event.color[2], event.color[3], 1.0)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle('line', startX, startY, barWidth, barHeight, 2, 2)
  love.graphics.setLineWidth(1)
end

-- Legacy full events display
function HUD.drawEvents(vw, vh, hudPanelHeight)
  -- Deprecated - using compact version in HUD
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
