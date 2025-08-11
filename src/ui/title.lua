local Title = {}

local blink = 0
local selected = 1
local items = { "Start", "Cosmetics", "Settings", "Quit" }

local function layoutButtons(vw, vh)
  local btnH = 56
  local btnW = math.min(360, math.floor(vw * 0.6))
  local gapY = 16
  local startY = math.floor(vh * 0.42)
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
  blink = blink + dt
end

function Title.keypressed(key)
  if key == 'up' or key == 'w' then selected = math.max(1, selected - 1) end
  if key == 'down' or key == 's' then selected = math.min(#items, selected + 1) end
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
  -- Title
  love.graphics.setColor(0.153, 0.953, 1.0, 1.0)
  love.graphics.setFont(love.graphics.newFont(48))
  local title = "NEON INVADERS"
  local tw = love.graphics.getFont():getWidth(title)
  love.graphics.print(title, (vw - tw) / 2, vh * 0.22)

  -- Vertical buttons
  local rects = layoutButtons(vw, vh)
  for i, r in ipairs(rects) do
    local isSel = (i == selected)
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle('line', r.x, r.y, r.w, r.h, 10, 10)
    if isSel then
      love.graphics.setColor(0.153, 0.953, 1.0, 0.25)
      love.graphics.rectangle('fill', r.x, r.y, r.w, r.h, 10, 10)
    end
    love.graphics.setColor(1,1,1,1)
    love.graphics.setFont(love.graphics.newFont(22))
    love.graphics.printf(items[i], r.x, r.y + r.h/2 - 12, r.w, 'center')
  end

  -- Help
  love.graphics.setFont(love.graphics.newFont(16))
  local os = (love.system and love.system.getOS) and love.system.getOS() or ""
  local prompt = (os == 'Android' or os == 'iOS') and "Tap to select" or "Up/Down to choose, Enter to confirm"
  love.graphics.setColor(1,1,1,0.9)
  love.graphics.printf(prompt, 0, vh * 0.88, vw, 'center')
end

return Title
