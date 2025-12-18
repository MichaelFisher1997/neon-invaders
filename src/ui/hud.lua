local HUD = {}
local Input = require("src.core.input")
local Fonts = require("src.ui.fonts")
local Neon = require("src.ui.neon_ui")

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
  
  -- Dark Glass Background
  love.graphics.setColor(0.02, 0.02, 0.05, 0.95)
  love.graphics.rectangle("fill", 0, 0, vw, panelH)
  
  -- Bottom glow line
  local lineColor = hasBoss and Neon.COLORS.magenta or Neon.COLORS.cyan
  love.graphics.setColor(lineColor[1], lineColor[2], lineColor[3], 0.8)
  love.graphics.setLineWidth(3)
  love.graphics.line(0, panelH - 2, vw, panelH - 2)
  love.graphics.setLineWidth(1)
  
  -- Vertical separators (Subtle)
  love.graphics.setColor(lineColor[1], lineColor[2], lineColor[3], 0.2)
  for i = 1, 3 do
    local x = sectionW * i
    love.graphics.line(x, 15, x, panelH - 15)
  end
  
  local labelFont = Fonts.get(11)
  local valueFont = Fonts.get(24)
  local padding = 20
  local labelY = 10
  local valueY = 24
  
  -- ===== SECTION 1: SCORE =====
  Neon.drawGlowText("SCORE", padding, labelY, labelFont, Neon.COLORS.cyan, Neon.COLORS.cyan, 1.0, 'left', sectionW)
  Neon.drawGlowText(tostring(score), padding, valueY, valueFont, Neon.COLORS.white, Neon.COLORS.cyan, 1.0, 'left', sectionW)
  
  -- ===== SECTION 2: CREDITS =====
  local s2X = sectionW + padding
  local gold = {1.0, 0.84, 0.0} -- Gold color
  Neon.drawGlowText("CREDITS", s2X, labelY, labelFont, gold, gold, 1.0, 'left', sectionW)
  Neon.drawGlowText(tostring(credits), s2X, valueY, valueFont, gold, gold, 1.0, 'left', sectionW)
  
  -- Multiplier
  local multiplier = Economy.getCreditMultiplier()
  if multiplier > 1 then
      local multText = string.format("x%d", multiplier)
      local creditsWidth = valueFont:getWidth(tostring(credits))
      Neon.drawGlowText(multText, s2X + creditsWidth + 10, valueY + 4, Fonts.get(16), Neon.COLORS.magenta, Neon.COLORS.magenta, 1.0, 'left', 50)
  end

  -- ===== SECTION 3: LIVES =====
  local s3X = sectionW * 2 + padding
  local livesColor = (lives <= 1) and Neon.COLORS.red or Neon.COLORS.cyan
  Neon.drawGlowText("LIVES", s3X, labelY, labelFont, livesColor, livesColor, 1.0, 'left', sectionW)
  Neon.drawGlowText(tostring(lives), s3X, valueY, valueFont, Neon.COLORS.white, livesColor, 1.0, 'left', sectionW)
  
  -- ===== SECTION 4: WAVE =====
  local s4X = sectionW * 3 + padding
  local r, g, b = getWaveColor(wave)
  local waveColor = {r, g, b}
  Neon.drawGlowText("WAVE", s4X, labelY, labelFont, Neon.COLORS.cyan, Neon.COLORS.cyan, 1.0, 'left', sectionW)
  Neon.drawGlowText(tostring(wave), s4X, valueY, valueFont, Neon.COLORS.white, waveColor, 1.0, 'left', sectionW)
  
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

local function drawNeonArrow(cx, cy, size, direction, color, isPressed)
    local r, g, b = unpack(color)
    local baseAlpha = isPressed and 1.0 or 0.6
    
    -- Arrow points
    local p1, p2, p3
    if direction == 'left' then
        p1 = {cx + size, cy - size}
        p2 = {cx - size, cy}
        p3 = {cx + size, cy + size}
    else
        p1 = {cx - size, cy - size}
        p2 = {cx + size, cy}
        p3 = {cx - size, cy + size}
    end
    
    -- Outer glow (3 layers)
    for i = 3, 1, -1 do
        local offset = i * 4
        love.graphics.setColor(r, g, b, 0.1 / i)
        local gp1, gp2, gp3
        -- Scale points outward for glow
        if direction == 'left' then
           love.graphics.polygon('fill', p1[1]+offset, p1[2]-offset, p2[1]-offset, p2[2], p3[1]+offset, p3[2]+offset)
        else
           love.graphics.polygon('fill', p1[1]-offset, p1[2]-offset, p2[1]+offset, p2[2], p3[1]-offset, p3[2]+offset)
        end
    end

    -- Main Arrow Fill
    love.graphics.setColor(r, g, b, baseAlpha)
    love.graphics.polygon('fill', p1[1], p1[2], p2[1], p2[2], p3[1], p3[2])
    
    -- Core (White/Bright)
    if isPressed then
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.polygon('fill', p1[1], p1[2], p2[1], p2[2], p3[1], p3[2])
    end
end

function HUD.drawLeftControls(vw, vh)
  local held = Input.getHeld()
  local color = Neon.COLORS.cyan
  local isPressed = held.left
  
  -- Neon Arrow
  local cx, cy = vw/2, vh/2
  local size = math.min(vw, vh) * 0.2
  drawNeonArrow(cx, cy, size, 'left', color, isPressed)
  
  -- Label (Subtle)
  Neon.drawGlowText("LEFT", 0, vh * 0.8, Fonts.get(16), Neon.COLORS.white, color, 0.8, 'center', vw)
end

function HUD.drawRightControls(vw, vh)
  local held = Input.getHeld()
  local color = Neon.COLORS.magenta
  local isPressed = held.right
  
  -- Neon Arrow
  local cx, cy = vw/2, vh/2
  local size = math.min(vw, vh) * 0.2
  drawNeonArrow(cx, cy, size, 'right', color, isPressed)
  
  -- Label (Subtle)
  Neon.drawGlowText("RIGHT", 0, vh * 0.8, Fonts.get(16), Neon.COLORS.white, color, 0.8, 'center', vw)
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
  
  Fonts.set(9)
  
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

-- Draw consistent side panel backgrounds (Glass + Neon Border)
function HUD.drawSidePanel(vw, vh, side)
  -- Glass Panel Background
  love.graphics.setColor(0.05, 0.05, 0.1, 0.85)
  love.graphics.rectangle('fill', 0, 0, vw, vh)
  
  -- Border color depends on side
  local color = (side == 'left') and Neon.COLORS.cyan or Neon.COLORS.magenta
  
  -- Neon Border
  love.graphics.setColor(color[1], color[2], color[3], 0.8)
  love.graphics.setLineWidth(2)
  
  if side == 'left' then
    -- Right border for left panel
    love.graphics.line(vw, 0, vw, vh)
  else
    -- Left border for right panel
    love.graphics.line(0, 0, 0, vh)
  end
  love.graphics.setLineWidth(1)
end

function HUD.drawPanelFrame(vw, vh)
  -- Deprecated, redirects to drawSidePanel if possible?
  -- But drawPanelFrame signature doesn't have side.
  -- Kept for compatibility if called elsewhere, but we will update main.lua to use drawSidePanel
  love.graphics.setColor(1,1,1,0.05)
  love.graphics.rectangle('fill', 0, 0, vw, vh)
end

return HUD
