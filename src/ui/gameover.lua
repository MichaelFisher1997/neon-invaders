local Highscores = require("src.systems.highscores")

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
end

local function layoutButtons(vw, vh)
  -- Vertical buttons centered
  local pad = 24
  local gapY = 16
  local btnH = 56
  local btnW = math.min(360, math.floor(vw * 0.6))
  local titleFont = love.graphics.newFont(32)
  local scoreFont = love.graphics.newFont(20)
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
  love.graphics.setColor(0, 0, 0, 0.55)
  love.graphics.rectangle("fill", 0, 0, vw, vh)
  love.graphics.setColor(1, 1, 1, 1)
  local rects, buttonsY, titleFont, scoreFont = layoutButtons(vw, vh)

  love.graphics.setFont(titleFont)
  love.graphics.printf("Game Over", 0, buttonsY - titleFont:getHeight() - scoreFont:getHeight() - 28, vw, "center")

  love.graphics.setFont(scoreFont)
  love.graphics.printf("Score: " .. tostring(score), 0, buttonsY - scoreFont:getHeight() - 8, vw, "center")

  -- Draw buttons
  for i, r in ipairs(rects) do
    local isSel = (i == selected)
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle('line', r.x, r.y, r.w, r.h, 10, 10)
    if isSel then
      love.graphics.setColor(0.153, 0.953, 1.0, 0.25)
      love.graphics.rectangle('fill', r.x, r.y, r.w, r.h, 10, 10)
    end
    love.graphics.setColor(1,1,1,1)
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.printf(options[i].label, r.x, r.y + r.h/2 - 12, r.w, 'center')
  end

  -- High scores below
  local list = Highscores.list()
  love.graphics.setFont(love.graphics.newFont(18))
  local y = rects[#rects].y + rects[#rects].h + 28
  love.graphics.printf("High Scores:", 0, y, vw, 'center')
  for i,entry in ipairs(list) do
    local line = string.format("%d) %d", i, entry.score)
    love.graphics.printf(line, 0, y + 22*i, vw, 'center')
  end

  -- Help text
  local os = (love.system and love.system.getOS) and love.system.getOS() or ""
  local help = (os == 'Android' or os == 'iOS') and 'Tap a button' or 'Up/Down to choose, Enter to confirm'
  love.graphics.setColor(1,1,1,0.85)
  love.graphics.setFont(love.graphics.newFont(16))
  love.graphics.printf(help, 0, vh - 24 - 16, vw, 'center')
end

return GameOver
