local Settings = require("src.systems.settings")

local UISettings = {}

local slider = { width = 420, height = 12 }
local selection = 1
local entries = {
  { type = 'slider', key = 'musicVolume', label = 'Music' },
  { type = 'slider', key = 'sfxVolume', label = 'SFX' },
  { type = 'select', key = 'difficulty', label = 'Difficulty', options = { 'easy', 'normal', 'hard' } },
  { type = 'action', key = 'back', label = 'Save & Back' },
}

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

  local x = vw/2 - slider.width/2
  local y = vh*0.30
  local lineH = 64

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
  local diffText = string.format("Difficulty: < %s >", opts[idx])
  love.graphics.printf(diffText, 0, y + lineH*2 + 8, vw, 'center')

  -- Back action
  love.graphics.setFont(love.graphics.newFont(22))
  love.graphics.setColor(1,1,1, selection==4 and 1 or 0.8)
  love.graphics.printf("Save & Back (Enter)", 0, y + lineH*3 + 8, vw, 'center')

  -- Selector highlight
  love.graphics.setColor(0.153, 0.953, 1.0, 0.25)
  love.graphics.rectangle('fill', x - 24, y + (selection-1)*lineH - 12, slider.width + 48, 48, 8, 8)

  love.graphics.setFont(love.graphics.newFont(14))
  love.graphics.setColor(1,1,1,0.7)
  love.graphics.printf("Use Up/Down to select, Left/Right to adjust. Enter to confirm.", 0, vh*0.88, vw, 'center')
end

return UISettings
