local Settings = require("src.systems.settings")
local Fonts = require("src.ui.fonts")

local UISettings = {}

local slider = { width = 500, height = 32 }
local selection = 1
local entries = {
  { type = 'slider', key = 'musicVolume', label = 'Music' },
  { type = 'slider', key = 'sfxVolume', label = 'SFX' },
  { type = 'select', key = 'difficulty', label = 'Difficulty', options = { 'easy', 'normal', 'hard' } },
  { type = 'action', key = 'clear', label = 'Clear User Data' },
  { type = 'action', key = 'back', label = 'Save & Back' },
}

local draggingIndex = nil
local showConfirmDialog = false
local confirmTimer = 0

local function layoutRects(vw, vh)
  local x = vw/2 - slider.width/2
  local y = vh*0.22
  local lineH = 100
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

local function clearUserData()
  -- Remove all save files
  local filesToRemove = {
    'settings.lua',
    'economy', 
    'cosmetics.lua',
    'highscores.lua',
    'save.dat'
  }
  
  for _, filename in ipairs(filesToRemove) do
    if love.filesystem.getInfo(filename) then
      love.filesystem.remove(filename)
    end
  end
  
  -- Reset all in-memory systems
  local Economy = require("src.systems.economy")
  local Cosmetics = require("src.systems.cosmetics")
  local Highscores = require("src.systems.highscores")
local Settings = require("src.systems.settings")
local Fonts = require("src.ui.fonts")
  
  Economy.reset()
  Cosmetics.reset()
  Highscores.reset()
  Settings.reset()
  
  -- Clear module caches to force fresh reload
  package.loaded["src.systems.economy"] = nil
  package.loaded["src.systems.cosmetics"] = nil  
  package.loaded["src.systems.highscores"] = nil
  package.loaded["src.systems.settings"] = nil
  
  showConfirmDialog = false
  confirmTimer = 0
  
  -- Force game to restart by returning to title
  local state = require("src.core.state")
  state.set("title")
end

local function playUISound()
  local ok, audio = pcall(require, 'src.audio.audio')
  if ok and audio then
    pcall(function() audio.play('ui_click') end)
  end
end

function UISettings.enter()
  selection = 1
  draggingIndex = nil
  showConfirmDialog = false
  confirmTimer = 0
end

local function drawSlider(x, y, value, label, isSelected)
  local w = slider.width
  local h = slider.height
  
  -- Selection background - only show when selected
  if isSelected then
    love.graphics.setColor(0.153, 0.953, 1.0, 0.15)
    -- Extend further right to cover percentage text (adds ~100px more)
    love.graphics.rectangle("fill", x - 40, y - 50, w + 180, h + 60, 12, 12)
  end
  
  -- Label - MUCH BIGGER AND CLEARER
  love.graphics.setFont(Fonts.get(36))
  local labelW = labelFont:getWidth(label)
  
  -- Multi-layer shadow for MAXIMUM visibility
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.print(label, x - 3, y - 43)
  love.graphics.print(label, x + 3, y - 43)
  love.graphics.print(label, x, y - 46)
  love.graphics.print(label, x, y - 40)
  
  -- Bright cyan glow
  love.graphics.setColor(0.153, 0.953, 1.0, 1)
  love.graphics.print(label, x, y - 43)
  
  -- Percentage - BIG AND BOLD
  love.graphics.setFont(Fonts.get(32))
  local percentText = string.format("%d%%", math.floor(value*100 + 0.5))
  
  -- Shadow
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.print(percentText, w + x + 18, y)
  love.graphics.print(percentText, w + x + 22, y)
  love.graphics.print(percentText, w + x + 20, y - 2)
  love.graphics.print(percentText, w + x + 20, y + 2)
  
  -- White percentage
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(percentText, w + x + 20, y)
  
  -- Track - thick black border
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", x - 3, y - 3, w + 6, h + 6, 12, 12)
  
  -- Track background - VERY DARK
  love.graphics.setColor(0.06, 0.06, 0.1, 1)
  love.graphics.rectangle("fill", x, y, w, h, 10, 10)
  
  -- Filled track - BRIGHT GLOWING CYAN
  if value > 0 then
    love.graphics.setColor(0.153, 0.953, 1.0, 1.0)
    love.graphics.rectangle("fill", x + 3, y + 3, (w - 6)*value, h - 6, 8, 8)
  end
  
  -- Track bright border - MUCH BRIGHTER when selected
  love.graphics.setColor(0.153, 0.953, 1.0, isSelected and 1 or 0.6)
  love.graphics.setLineWidth(isSelected and 5 or 3)
  love.graphics.rectangle("line", x, y, w, h, 10, 10)
  love.graphics.setLineWidth(1)
  
  -- MUCH BIGGER knob
  local cx = x + w*value
  local cy = y + h/2
  
  -- Knob glow (huge)
  love.graphics.setColor(0.153, 0.953, 1.0, 0.4)
  love.graphics.circle('fill', cx, cy, 26)
  
  -- Knob shadow
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.circle('fill', cx + 2, cy + 2, 20)
  
  -- Knob body - BRIGHT WHITE
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.circle('fill', cx, cy, 20)
  
  -- Knob border - THICK AND BRIGHT
  love.graphics.setColor(0.153, 0.953, 1.0, 1)
  love.graphics.setLineWidth(5)
  love.graphics.circle('line', cx, cy, 20)
  love.graphics.setLineWidth(1)
  
  -- Knob center
  love.graphics.setColor(0.153, 0.953, 1.0, 1)
  love.graphics.circle('fill', cx, cy, 8)
end

function UISettings.update(dt)
  -- Update confirmation dialog timer
  if showConfirmDialog and confirmTimer > 0 then
    confirmTimer = confirmTimer - dt
    if confirmTimer <= 0 then
      showConfirmDialog = false
      confirmTimer = 0
    end
  end
end

function UISettings.keypressed(key)
  -- Handle confirmation dialog first
  if showConfirmDialog then
    if key == 'y' or key == 'Y' then
      clearUserData()
      playUISound()
    elseif key == 'n' or key == 'N' or key == 'escape' then
      showConfirmDialog = false
      confirmTimer = 0
      playUISound()
    end
    return
  end
  
  local s = Settings.get()
  if key == 'up' or key == 'w' then selection = math.max(1, selection - 1) return end
  if key == 'down' or key == 's' then selection = math.min(#entries, selection + 1) return end
  if key == 'return' or key == 'kpenter' then
    local cur = entries[selection]
    if cur.type == 'action' then
      if cur.key == 'clear' then
        playUISound()
        showConfirmDialog = true
        confirmTimer = 3.0 -- Show dialog for 3 seconds
      elseif cur.key == 'back' then
        playUISound()
        local state = require("src.core.state")
        state.set("title")
      end
    end
    return
  end

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
  
  -- HUGE TITLE with dramatic styling
  love.graphics.setFont(Fonts.get(64))
  local titleY = vh*0.06
  
  -- Multiple shadow layers for depth
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.printf("Settings", -4, titleY, vw, 'center')
  love.graphics.printf("Settings", 4, titleY, vw, 'center')
  love.graphics.printf("Settings", 0, titleY - 4, vw, 'center')
  love.graphics.printf("Settings", 0, titleY + 4, vw, 'center')
  
  -- Bright cyan glow
  love.graphics.setColor(0.153, 0.953, 1.0, 1)
  love.graphics.printf("Settings", 0, titleY, vw, 'center')

  local rects, x, y, lineH = layoutRects(vw, vh)

  -- Music slider
  drawSlider(x, y, s.musicVolume, "Music", selection == 1)
  -- SFX slider
  drawSlider(x, y + lineH, s.sfxVolume, "SFX", selection == 2)

  -- Difficulty selector - MUCH MORE VISIBLE
  local opts = { 'easy', 'normal', 'hard' }
  local displayOpts = { 'EASY', 'NORMAL', 'HARD' }
  local idx = 1
  for i,o in ipairs(opts) do if o==s.difficulty then idx=i end end
  local diffY = y + lineH*2 + 8
  local diffText = displayOpts[idx]
  local centerX = vw/2
  local boxW, boxH = 60, 50
  local leftX = centerX - 150 - boxW
  local rightX = centerX + 150
  
  -- Selection background for difficulty - covers all three elements
  if selection == 3 then
    love.graphics.setColor(0.153, 0.953, 1.0, 0.15)
    -- Calculate to cover: left arrow at (leftX), center box, right arrow at (rightX + boxW)
    -- leftX = centerX - 150 - boxW = centerX - 210
    -- rightX + boxW = centerX + 150 + 60 = centerX + 210
    -- Total width needed: 420, plus padding
    love.graphics.rectangle('fill', leftX - 10, diffY - 55, (rightX + boxW) - leftX + 20, 110, 12, 12)
  end
  
  -- Label - BIG AND BRIGHT
  love.graphics.setFont(Fonts.get(32))
  local labelY = diffY - 48
  
  -- Label shadow
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.printf("Difficulty", -3, labelY, vw, 'center')
  love.graphics.printf("Difficulty", 3, labelY, vw, 'center')
  love.graphics.printf("Difficulty", 0, labelY - 3, vw, 'center')
  love.graphics.printf("Difficulty", 0, labelY + 3, vw, 'center')
  
  -- Label cyan glow
  love.graphics.setColor(0.153, 0.953, 1.0, 1)
  love.graphics.printf("Difficulty", 0, labelY, vw, 'center')
  
  -- Value box - dark background
  love.graphics.setColor(0.06, 0.06, 0.1, 1)
  love.graphics.rectangle('fill', centerX - 100, diffY - 5, 200, boxH, 12, 12)
  
  -- Value box border - BRIGHTER when selected
  love.graphics.setColor(0.153, 0.953, 1.0, selection==3 and 1 or 0.6)
  love.graphics.setLineWidth(selection==3 and 5 or 3)
  love.graphics.rectangle('line', centerX - 100, diffY - 5, 200, boxH, 12, 12)
  love.graphics.setLineWidth(1)
  
  -- Value text - HUGE
  love.graphics.setFont(Fonts.get(28))
  
  -- Value shadow
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.printf(diffText, -2, diffY + 8, vw, 'center')
  love.graphics.printf(diffText, 2, diffY + 8, vw, 'center')
  love.graphics.printf(diffText, 0, diffY + 6, vw, 'center')
  love.graphics.printf(diffText, 0, diffY + 10, vw, 'center')
  
  -- Value text - bright white
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf(diffText, 0, diffY + 8, vw, 'center')
  
  -- Left arrow button
  love.graphics.setColor(0.06, 0.06, 0.1, 1)
  love.graphics.rectangle('fill', leftX, diffY - 5, boxW, boxH, 12, 12)
  
  love.graphics.setColor(0.153, 0.953, 1.0, selection==3 and 1 or 0.6)
  love.graphics.setLineWidth(selection==3 and 5 or 3)
  love.graphics.rectangle('line', leftX, diffY - 5, boxW, boxH, 12, 12)
  love.graphics.setLineWidth(1)
  
  love.graphics.setFont(Fonts.get(36))
  
  -- Arrow shadow
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.printf('<', leftX - 2, diffY + 4, boxW, 'center')
  love.graphics.printf('<', leftX + 2, diffY + 4, boxW, 'center')
  
  -- Arrow text
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf('<', leftX, diffY + 4, boxW, 'center')
  
  -- Right arrow button
  love.graphics.setColor(0.06, 0.06, 0.1, 1)
  love.graphics.rectangle('fill', rightX, diffY - 5, boxW, boxH, 12, 12)
  
  love.graphics.setColor(0.153, 0.953, 1.0, selection==3 and 1 or 0.6)
  love.graphics.setLineWidth(selection==3 and 5 or 3)
  love.graphics.rectangle('line', rightX, diffY - 5, boxW, boxH, 12, 12)
  love.graphics.setLineWidth(1)
  
  -- Arrow shadow
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.printf('>', rightX - 2, diffY + 4, boxW, 'center')
  love.graphics.printf('>', rightX + 2, diffY + 4, boxW, 'center')
  
  -- Arrow text
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf('>', rightX, diffY + 4, boxW, 'center')

  -- Clear User Data button - BIG AND OBVIOUS
  local clearY = y + lineH*3 + 8
  love.graphics.setFont(Fonts.get(26))
  
  -- Selection background
  if selection == 4 then
    love.graphics.setColor(1, 0.2, 0.2, 0.15)
    love.graphics.rectangle('fill', centerX - 170, clearY - 5, 340, 50, 12, 12)
  end
  
  -- Border - MUCH BRIGHTER when selected
  love.graphics.setColor(1, 0.2, 0.2, selection==4 and 1 or 0.6)
  love.graphics.setLineWidth(selection==4 and 5 or 3)
  love.graphics.rectangle('line', centerX - 170, clearY - 5, 340, 50, 12, 12)
  love.graphics.setLineWidth(1)
  
  -- Text shadow
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.printf("Clear User Data", -2, clearY + 8, vw, 'center')
  love.graphics.printf("Clear User Data", 2, clearY + 8, vw, 'center')
  
  -- Text - red/white
  love.graphics.setColor(1, 0.5, 0.5, selection==4 and 1 or 0.9)
  love.graphics.printf("Clear User Data", 0, clearY + 8, vw, 'center')

  -- Save & Back button - BIG AND CLEAR
  local backY = y + lineH*4 + 8
  
  -- Selection background
  if selection == 5 then
    love.graphics.setColor(0.153, 0.953, 1.0, 0.15)
    love.graphics.rectangle('fill', centerX - 190, backY - 5, 380, 50, 12, 12)
  end
  
  -- Border - MUCH BRIGHTER when selected
  love.graphics.setColor(0.153, 0.953, 1.0, selection==5 and 1 or 0.6)
  love.graphics.setLineWidth(selection==5 and 5 or 3)
  love.graphics.rectangle('line', centerX - 190, backY - 5, 380, 50, 12, 12)
  love.graphics.setLineWidth(1)
  
  -- Text shadow
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.printf("Save & Back (Enter)", -2, backY + 8, vw, 'center')
  love.graphics.printf("Save & Back (Enter)", 2, backY + 8, vw, 'center')
  
  -- Text - white
  love.graphics.setColor(1, 1, 1, selection==5 and 1 or 0.9)
  love.graphics.printf("Save & Back (Enter)", 0, backY + 8, vw, 'center')

  -- Selector highlight removed - individual elements already show selection state via their borders

  -- Help text - BIGGER AND CLEARER (moved to very bottom)
  love.graphics.setFont(Fonts.get(18))
  
  -- Shadow
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.printf("Tap/drag sliders. Tap arrows to change difficulty. Enter or tap Back to save.", -1, vh*0.92 + 1, vw, 'center')
  love.graphics.printf("Tap/drag sliders. Tap arrows to change difficulty. Enter or tap Back to save.", 1, vh*0.92 + 1, vw, 'center')
  
  -- Text
  love.graphics.setColor(0.8, 0.8, 0.8, 1)
  love.graphics.printf("Tap/drag sliders. Tap arrows to change difficulty. Enter or tap Back to save.", 0, vh*0.92, vw, 'center')

  -- Confirmation dialog
  if showConfirmDialog then
    local dialogW, dialogH = 400, 200
    local dialogX = (vw - dialogW) / 2
    local dialogY = (vh - dialogH) / 2
    
    -- Darken background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', 0, 0, vw, vh)
    
    -- Dialog box
    love.graphics.setColor(0.2, 0.2, 0.3, 0.95)
    love.graphics.rectangle('fill', dialogX, dialogY, dialogW, dialogH, 12, 12)
    love.graphics.setColor(0.5, 0.7, 1.0, 1.0)
    love.graphics.rectangle('line', dialogX, dialogY, dialogW, dialogH, 12, 12)
    
    -- Dialog text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(Fonts.get(20))
    love.graphics.printf("Clear All User Data?", dialogX, dialogY + 30, dialogW, 'center')
    
    love.graphics.setFont(Fonts.get(16))
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.printf("This will permanently delete:", dialogX, dialogY + 70, dialogW, 'center')
    love.graphics.printf("• All settings and preferences", dialogX, dialogY + 90, dialogW, 'center')
    love.graphics.printf("• Economy progress and upgrades", dialogX, dialogY + 110, dialogW, 'center')
    love.graphics.printf("• Cosmetics and high scores", dialogX, dialogY + 130, dialogW, 'center')
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Press Y to confirm, N to cancel", dialogX, dialogY + 160, dialogW, 'center')
    
    -- Auto-cancel timer
    if confirmTimer > 0 then
      love.graphics.setColor(1, 1, 0.5, 1)
      love.graphics.printf(string.format("Auto-cancel in %.1f seconds", confirmTimer), dialogX, dialogY + 180, dialogW, 'center')
    end
  end
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
    playUISound()
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
    playUISound()
    return nil
  elseif entry.type == 'action' then
    if entry.key == 'clear' then
      playUISound()
      showConfirmDialog = true
      confirmTimer = 3.0 -- Show dialog for 3 seconds
    elseif entry.key == 'back' then
      playUISound()
      return 'back'
    end
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

function UISettings.isConfirmationActive()
  return showConfirmDialog
end

return UISettings