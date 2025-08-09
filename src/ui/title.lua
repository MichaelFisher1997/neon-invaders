local Title = {}

local blink = 0
local selected = 1
local items = { "Start", "Settings", "Quit" }

function Title.update(dt)
  blink = blink + dt
end

function Title.keypressed(key)
  if key == 'up' or key == 'w' then selected = math.max(1, selected - 1) end
  if key == 'down' or key == 's' then selected = math.min(#items, selected + 1) end
  if key == 'return' or key == 'enter' or key == 'space' then
    require('src.audio.audio').play('ui_click')
  end
end

function Title.getSelected()
  return items[selected]
end

function Title.draw(vw, vh)
  love.graphics.setColor(0.153, 0.953, 1.0, 1.0)
  love.graphics.setFont(love.graphics.newFont(48))
  local title = "NEON INVADERS"
  local tw = love.graphics.getFont():getWidth(title)
  love.graphics.print(title, (vw - tw) / 2, vh * 0.22)

  love.graphics.setFont(love.graphics.newFont(26))
  for i, label in ipairs(items) do
    local y = vh * 0.40 + (i-1) * 48
    local text = (i == selected) and ("> " .. label .. " <") or label
    local w = love.graphics.getFont():getWidth(text)
    love.graphics.setColor(1,1,1, i == selected and 1 or 0.7)
    love.graphics.print(text, (vw - w)/2, y)
  end

  love.graphics.setFont(love.graphics.newFont(16))
  local prompt = ((math.floor(blink*2) % 2) == 0) and "Enter/Space: Select" or "Up/Down to navigate"
  love.graphics.setColor(1,1,1,0.9)
  love.graphics.printf(prompt, 0, vh * 0.75, vw, 'center')
end

return Title
