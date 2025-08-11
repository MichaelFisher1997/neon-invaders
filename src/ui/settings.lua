local Settings = require("src.systems.settings")

local UISettings = {}

local slider = { width = 420, height = 16 }
local selection = 1
local entries = {
  { type = 'slider', key = 'musicVolume', label = 'Music' },
  { type = 'slider', key = 'sfxVolume', label = 'SFX' },
  { type = 'select', key = 'difficulty', label = 'Difficulty', options = { 'easy', 'normal', 'hard' } },
  { type = 'action', key = 'back', label = 'Save & Back' },
}

local draggingIndex = nil

local function layoutRects(vw, vh)
  local x = vw/2 - slider.width/2
  local y = vh*0.30
  local lineH = 64
  local rects = {}
  local boxW = 44 -- difficulty arrow box width
  local padArrow = 12
  for i = 1, #entries do
    local rx = x - 24
    local ry = y + (i-1)*lineH - 12
    local rw = slider.width + 48
    local rh = 48
    if entries[i].type == 'select' then
      -- widen to include left/right arrow hit targets
      rx = rx - (boxW + padArrow)
      rw = rw + 2*(boxW + padArrow)
    end
    rects[i] = {x=rx, y=ry, w=rw, h=rh, lineY = y + (i-1)*lineH}
  end
  return rects, x, y, lineH
end

function UISettings.enter()
  selection = 1
  draggingIndex = nil
end

local function drawSlider(x, y, value, label)
  local w = slider.width
  local h = slider.height
  love.graphics.setColor(1,1,1,0.2)
  love.graphics.rectangle("fill", x, y, w, h, 6, 6)
  love.graphics.setColor(0.153, 0.953, 1.0, 1.0)
  love.graphics.rectangle("fill", x, y, w*value, h, 6, 6)
  love.graphics.setColor(1,1,1,1)
  love.graphics.setFont(love.graphics.newFont(18))
  love.graphics.print(label .. string.format(": %d%%", math.floor(value*100 + 0.5)), x, y - 26)
  -- knob handle for touch friendliness
  local cx = x + w*value
  local cy = y + h/2
  love.graphics.setColor(1,1,1,1)
  love.graphics.circle('fill', cx, cy, 8)
  love.graphics.setColor(0,0,0,1)
  love.graphics.circle('line', cx, cy, 8)
end

function UISettings.update(dt)
  -- no-op; discrete changes handled in keypressed
end

function UISettings.keypressed(key)
  local s = Settings.get()
  if key == 'up' or key == 'w' then selection = math.max(1, selection - 1) return end
  if key == 'down' or key == 's' then selection = math.min(#entries, selection + 1) return end

  local cur = entries[selection]
  local function adjustSlider(delta)
    local step = 0.05
    local v = s[cur.key] or 0
    v = v + delta * step
    v = math.max(0, math.min(1, v))
    -- snap to nearest 5%
    v = math.floor(v/step + 0.5) * step
    s[cur.key] = v
  end

  if key == 'left' or key == 'a' then
    if cur.type == 'slider' then adjustSlider(-1) end
    if cur.type == 'select' then
      local opts = cur.options
      local idx = 1
      for i,o in ipairs(opts) do if o==s.difficulty then idx=i end end
      idx = math.max(1, idx - 1)
      s.difficulty = opts[idx]
    end
  elseif key == 'right' or key == 'd' then
    if cur.type == 'slider' then adjustSlider(1) end
    if cur.type == 'select' then
      local opts = cur.options
      local idx = 1
      for i,o in ipairs(opts) do if o==s.difficulty then idx=i end end
      idx = math.min(#opts, idx + 1)
      s.difficulty = opts[idx]
    end
  end
end

function UISettings.draw(vw, vh)
  local s = Settings.get()
  love.graphics.setColor(1,1,1,1)
  love.graphics.setFont(love.graphics.newFont(36))
  love.graphics.printf("Settings", 0, vh*0.18, vw, 'center')

  local rects, x, y, lineH = layoutRects(vw, vh)

  -- Music slider
  drawSlider(x, y, s.musicVolume, "Music")
  -- SFX slider
  drawSlider(x, y + lineH, s.sfxVolume, "SFX")

  -- Difficulty selector
  local opts = { 'easy', 'normal', 'hard' }
  local idx = 1
  for i,o in ipairs(opts) do if o==s.difficulty then idx=i end end
  love.graphics.setFont(love.graphics.newFont(22))
  love.graphics.setColor(1,1,1, selection==3 and 1 or 0.8)
  local diffY = y + lineH*2 + 8
  local diffText = string.format("%s", opts[idx])
  -- draw left/right arrow boxes for clearer touch targets
  local centerX = vw/2
  local boxW, boxH = 44, 36
  local leftX = centerX - (slider.width/2) - boxW - 12
  local rightX = centerX + (slider.width/2) + 12
  -- Label
  local labelY = diffY - 28
  love.graphics.printf("Difficulty:", 0, labelY, vw, 'center')
  -- Value box
  love.graphics.setColor(1,1,1,1)
  love.graphics.rectangle('line', centerX - 80, diffY - 4, 160, boxH, 8, 8)
  love.graphics.printf(diffText, centerX - 80, diffY + 6, 160, 'center')
  -- Arrows
  love.graphics.rectangle('line', leftX, diffY - 4, boxW, boxH, 8, 8)
  love.graphics.rectangle('line', rightX, diffY - 4, boxW, boxH, 8, 8)
  love.graphics.printf('<', leftX, diffY + 6, boxW, 'center')
  love.graphics.printf('>', rightX, diffY + 6, boxW, 'center')

  -- Back action
  love.graphics.setFont(love.graphics.newFont(22))
  love.graphics.setColor(1,1,1, selection==4 and 1 or 0.8)
  love.graphics.printf("Save & Back (Enter)", 0, y + lineH*3 + 8, vw, 'center')

  -- Selector highlight
  love.graphics.setColor(0.153, 0.953, 1.0, 0.25)
  love.graphics.rectangle('fill', rects[selection].x, rects[selection].y, rects[selection].w, rects[selection].h, 8, 8)

  love.graphics.setFont(love.graphics.newFont(14))
  love.graphics.setColor(1,1,1,0.7)
  love.graphics.printf("Tap/drag sliders. Tap arrows to change difficulty. Enter or tap Back to save.", 0, vh*0.88, vw, 'center')
end

function UISettings.pointerPressed(vw, vh, lx, ly)
  local s = Settings.get()
  local rects, x, y, lineH = layoutRects(vw, vh)
  local idx = nil
  for i, r in ipairs(rects) do
    if lx >= r.x and lx <= r.x + r.w and ly >= r.y and ly <= r.y + r.h then
      idx = i; break
    end
  end
  if not idx then return nil end
  selection = idx
  local entry = entries[idx]

  local function snap(v)
    local step = 0.05
    v = math.max(0, math.min(1, v))
    return math.floor(v/step + 0.5) * step
  end

  if entry.type == 'slider' then
    -- Map tap X within slider bar
    local barX = x
    local barY = y + (idx-1)*lineH
    local rel = (lx - barX) / slider.width
    s[entry.key] = snap(rel)
    require('src.audio.audio').play('ui_click')
    draggingIndex = idx
    return nil
  elseif entry.type == 'select' then
    -- Left arrow, right arrow, or center cycles (difficulty)
    local opts = entry.options
    local cur = 1
    for i,o in ipairs(opts) do if o == s.difficulty then cur = i end end
    local centerX = vw/2
    local boxW, boxH = 44, 36
    local leftX = centerX - (slider.width/2) - boxW - 12
    local rightX = centerX + (slider.width/2) + 12
    if lx >= leftX and lx <= leftX + boxW then
      cur = math.max(1, cur - 1)
    elseif lx >= rightX and lx <= rightX + boxW then
      cur = math.min(#opts, cur + 1)
    else
      cur = (cur % #opts) + 1
    end
    s.difficulty = opts[cur]
    require('src.audio.audio').play('ui_click')
    return nil
  elseif entry.type == 'action' and entry.key == 'back' then
    require('src.audio.audio').play('ui_click')
    return 'back'
  end
  return nil
end

function UISettings.pointerMoved(vw, vh, lx, ly)
  if not draggingIndex then return nil end
  local s = Settings.get()
  local _, x, y, lineH = layoutRects(vw, vh)
  local barX = x
  local rel = (lx - barX) / slider.width
  -- snap during drag but with finer step
  local v = math.max(0, math.min(1, rel))
  local step = 0.01
  v = math.floor(v/step + 0.5) * step
  local entry = entries[draggingIndex]
  if entry and entry.type == 'slider' then
    s[entry.key] = v
  end
  return nil
end

function UISettings.pointerReleased()
  draggingIndex = nil
end

return UISettings
