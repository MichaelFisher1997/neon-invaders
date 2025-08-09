local Pause = {}

function Pause.draw(vw, vh)
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 0, 0, vw, vh)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(love.graphics.newFont(28))
  local text = "Paused\n[Esc] Resume  |  [R] Restart  |  [Q] Quit"
  local tw = love.graphics.getFont():getWidth("Paused")
  love.graphics.printf(text, 0, vh * 0.35, vw, "center")
end

return Pause
