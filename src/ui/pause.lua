local Pause = {}
local Fonts = require("src.ui.fonts")

function Pause.draw(vw, vh)
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 0, 0, vw, vh)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Fonts.get(28))
  local text = "Paused"
  local tw = love.graphics.getFont():getWidth("Paused")
  love.graphics.printf(text, 0, vh * 0.25, vw, "center")
  
  -- Draw touch-friendly buttons
  local buttonW, buttonH = 200, 50
  local centerX = vw / 2
  local buttonY = vh * 0.45
  local buttonSpacing = 60
  
  local buttons = {
    { y = buttonY, label = 'Resume', action = 'resume' },
    { y = buttonY + buttonSpacing, label = 'Restart', action = 'restart' },
    { y = buttonY + buttonSpacing * 2, label = 'Quit', action = 'quit' }
  }
  
  for i, btn in ipairs(buttons) do
    local btnX = centerX - buttonW / 2
    
    -- Button background
    love.graphics.setColor(0.2, 0.4, 0.8, 0.8)
    love.graphics.rectangle("fill", btnX, btn.y, buttonW, buttonH, 8, 8)
    
    -- Button border
    love.graphics.setColor(0.5, 0.7, 1.0, 1.0)
    love.graphics.rectangle("line", btnX, btn.y, buttonW, buttonH, 8, 8)
    
    -- Button text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(Fonts.get(20))
    love.graphics.printf(btn.label, btnX, btn.y + 15, buttonW, "center")
  end
  
  -- Instructions
  love.graphics.setFont(Fonts.get(16))
  love.graphics.setColor(0.7, 0.7, 0.7, 1)
  love.graphics.printf("Tap a button or use keyboard shortcuts", 0, vh * 0.85, vw, "center")
end

function Pause.pointerPressed(vw, vh, lx, ly)
  local buttonW, buttonH = 200, 50
  local centerX = vw / 2
  local buttonY = vh * 0.45
  local buttonSpacing = 60
  
  local buttons = {
    { y = buttonY, action = 'resume' },
    { y = buttonY + buttonSpacing, action = 'restart' },
    { y = buttonY + buttonSpacing * 2, action = 'quit' }
  }
  
  for _, btn in ipairs(buttons) do
    local btnX = centerX - buttonW / 2
    if lx >= btnX and lx <= btnX + buttonW and
       ly >= btn.y and ly <= btn.y + buttonH then
      require('src.audio.audio').play('ui_click')
      return btn.action
    end
  end
  return nil
end

return Pause
