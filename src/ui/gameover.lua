local Highscores = require("src.systems.highscores")
local Fonts = require("src.ui.fonts")
local InputMode = require("src.core.inputmode")
local Neon = require("src.ui.neon_ui")

local GameOver = {}

local submitted = false
local selected = 1
local options = {
  { id = 'retry', label = 'Retry' },
  { id = 'menu',  label = 'Menu'  },
  { id = 'quit',  label = 'Quit'  },
}

function GameOver.enter()
  submitted = false
  selected = 1
  InputMode.setTouchDelay() -- Prevent accidental touches
end

local function layoutButtons(vw, vh)
  -- Vertical buttons centered
  local pad = 24
  local gapY = 16
  local btnH = 56
  local btnW = math.min(360, math.floor(vw * 0.6))
  local titleFont = Fonts.get(32)
  local scoreFont = Fonts.get(20)
  local startY = math.floor(vh * 0.38)
  local rects = {}
  for i,_ in ipairs(options) do
    local x = math.floor((vw - btnW)/2 + 0.5)
    local y = startY + (i-1) * (btnH + gapY)
    rects[i] = { x = x, y = y, w = btnW, h = btnH }
  end
  return rects, startY, titleFont, scoreFont
end

function GameOver.keypressed(key)
  if key == 'up' or key == 'w' then selected = math.max(1, selected - 1) end
  if key == 'down' or key == 's' then selected = math.min(#options, selected + 1) end
  if key == 'tab' then selected = (selected % #options) + 1 end
  if key == 'return' or key == 'enter' or key == 'space' then
    return options[selected].id
  end
  if key == 'q' then
    return 'menu' -- previous behavior mapped to Menu for keyboard convenience
  end
  return nil
end

function GameOver.pointerPressed(vw, vh, lx, ly)
  local rects = select(1, layoutButtons(vw, vh))
  for i, r in ipairs(rects) do
    if lx >= r.x and lx <= r.x + r.w and ly >= r.y and ly <= r.y + r.h then
      selected = i
      require('src.audio.audio').play('ui_click')
      return options[i].id
    end
  end
  return nil
end

function GameOver.draw(score, vw, vh)
  if not submitted then
    Highscores.submit(score)
    submitted = true
  end

  local layout = layoutButtons(vw, vh)
  
  -- Dim background
  love.graphics.setColor(0, 0, 0, 0.85)
  love.graphics.rectangle("fill", 0, 0, vw, vh)
  
  -- Title
  Neon.drawGlowText("GAME OVER", 0, layout[1].y - 120, Fonts.get(48), Neon.COLORS.white, Neon.COLORS.red, 1.0, 'center', vw)
  
  -- Current Score
  Neon.drawGlowText("Score: " .. tostring(score), 0, layout[1].y - 60, Fonts.get(24), Neon.COLORS.cyan, Neon.COLORS.cyan, 1.0, 'center', vw)

  -- Draw buttons
  for i, r in ipairs(layout) do
    local isSel = (i == selected)
    -- Color code buttons: Retry=Green, Menu=Cyan, Quit=Red
    local color = Neon.COLORS.cyan
    if i == 1 then color = Neon.COLORS.green end
    if i == 3 then color = Neon.COLORS.red end
    
    -- Pass 'isSel' as second argument to drawButton (isHovered/isSelected)
    -- Note: Neon.drawButton signature is (text, rect, isHovered, color)
    Neon.drawButton(options[i].label, r, isSel, color)
  end

  -- High scores below
  local list = Highscores.list()
  local y = layout[#layout].y + layout[#layout].h + 30
  
  Neon.drawGlowText("HIGH SCORES", 0, y, Fonts.get(20), Neon.COLORS.gold, Neon.COLORS.gold, 1.0, 'center', vw)
  
  for i,entry in ipairs(list) do
    local line = string.format("%d. %d", i, entry.score)
    -- Top score glow
    local color = (i == 1) and Neon.COLORS.gold or Neon.COLORS.white
    local glowColor = (i == 1) and Neon.COLORS.gold or Neon.COLORS.blue
    Neon.drawGlowText(line, 0, y + 25 + 25*i, Fonts.get(18), color, glowColor, 0.8, 'center', vw)
  end

  -- Help text
  local help = InputMode.isTouchMode() and 'Tap to select' or 'Arrows/WASD to choose, Enter to confirm'
  love.graphics.setColor(1,1,1,0.5)
  love.graphics.setFont(Fonts.get(14))
  love.graphics.printf(help, 0, vh - 40, vw, 'center')
end

return GameOver
