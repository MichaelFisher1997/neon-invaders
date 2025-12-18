local Title = {}
local Fonts = require("src.ui.fonts")
local Neon = require("src.ui.neon_ui")

local timer = 0
local selected = 1
local items = { "Start", "Boss Gallery", "Upgrades", "Cosmetics", "Settings", "Quit" }

-- Version number - increment last number for each change
local VERSION = "v0.01-beta-3-neon"

local function layoutButtons(vw, vh)
  local btnH = 55
  local btnW = math.min(380, math.floor(vw * 0.65))
  local gapY = 14
  local startY = math.floor(vh * 0.32)
  local rects = {}
  for i,_ in ipairs(items) do
    local x = math.floor((vw - btnW)/2 + 0.5)
    local y = startY + (i-1) * (btnH + gapY)
    rects[i] = { x = x, y = y, w = btnW, h = btnH }
  end
  return rects
end

function Title.enter()
  selected = 1
end

function Title.update(dt)
  timer = timer + dt
end

function Title.keypressed(key)
  if key == 'up' or key == 'w' then 
    selected = math.max(1, selected - 1) 
    require('src.audio.audio').play('ui_hover')
  end
  if key == 'down' or key == 's' then 
    selected = math.min(#items, selected + 1) 
    require('src.audio.audio').play('ui_hover')
  end
  if key == 'return' or key == 'enter' or key == 'space' then
    require('src.audio.audio').play('ui_click')
  end
end

function Title.pointerPressed(vw, vh, lx, ly)
  local rects = layoutButtons(vw, vh)
  for i, r in ipairs(rects) do
    if lx >= r.x and lx <= r.x + r.w and ly >= r.y and ly <= r.y + r.h then
      selected = i
      require('src.audio.audio').play('ui_click')
      return items[i]
    end
  end
  return nil
end

function Title.getSelected()
  return items[selected]
end

function Title.draw(vw, vh)
  -- Title with Sine Wave Float
  local titleScale = 1.0 + math.sin(timer * 2) * 0.02
  local titleY = vh * 0.16 + math.sin(timer * 1.5) * 8
  
  love.graphics.setFont(Fonts.get(48))
  local title = "NEON INVADERS"
  local tw = love.graphics.getFont():getWidth(title)
  local titleX = (vw - tw * titleScale) / 2
  
  Neon.drawGlowText(title, titleX, titleY, Fonts.get(48), Neon.COLORS.cyan, Neon.COLORS.magenta, titleScale)

  -- Subtle grid line at top/bottom of title to frame it
  love.graphics.setColor(1, 1, 1, 0.1)
  love.graphics.line(titleX - 40, titleY + 60, titleX + tw*titleScale + 40, titleY + 60)

  -- Draw Buttons
  local rects = layoutButtons(vw, vh)
  for i, r in ipairs(rects) do
    Neon.drawButton(items[i], r, i == selected)
  end

  -- Version number (bottom left)
  love.graphics.setFont(Fonts.get(12))
  love.graphics.setColor(1, 1, 1, 0.4)
  love.graphics.print(VERSION, 10, vh - 25)

  -- Help Prompt
  love.graphics.setFont(Fonts.get(16))
  local os = (love.system and love.system.getOS) and love.system.getOS() or ""
  local prompt = (os == 'Android' or os == 'iOS') and "Tap to select" or "Up/Down to choose, Enter to confirm"
  
  -- Blinking text for prompt
  local promptAlpha = 0.5 + math.sin(timer * 4) * 0.4
  love.graphics.setColor(1, 1, 1, promptAlpha)
  love.graphics.printf(prompt, 0, vh * 0.92, vw, 'center')
end

return Title
