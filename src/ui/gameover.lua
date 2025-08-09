local Highscores = require("src.systems.highscores")

local GameOver = {}

local submitted = false

function GameOver.draw(score, vw, vh)
  if not submitted then
    Highscores.submit(score)
    submitted = true
  end
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 0, 0, vw, vh)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(love.graphics.newFont(32))
  love.graphics.printf("Game Over", 0, vh * 0.3, vw, "center")
  love.graphics.setFont(love.graphics.newFont(20))
  love.graphics.printf("Score: " .. tostring(score) .. "\nPress Enter to Retry or Q to Quit", 0, vh * 0.42, vw, "center")

  -- Show top 5
  local list = Highscores.list()
  love.graphics.setFont(love.graphics.newFont(18))
  local y = vh * 0.55
  love.graphics.printf("High Scores:", 0, y, vw, 'center')
  for i,entry in ipairs(list) do
    local line = string.format("%d) %d", i, entry.score)
    love.graphics.printf(line, 0, y + 22*i, vw, 'center')
  end
end

return GameOver
