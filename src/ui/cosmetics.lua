local Cosmetics = require("src.systems.cosmetics")
local audio = require("src.audio.audio")

local UICosmetics = {}

local selection = 1 -- 1..#items
local swipe = { startX = nil, startY = nil, tracking = false }

-- local helper for dynamic RGB preview
local function rgbTripColor(time)
  local t = time * 0.6
  local r = 0.5 + 0.5 * math.sin(t)
  local g = 0.5 + 0.5 * math.sin(t + 2.0944) -- +120°
  local b = 0.5 + 0.5 * math.sin(t + 4.1888) -- +240°
  return { r, g, b, 1.0 }
end

local function items()
  return Cosmetics.all()
end

local function findIndexById(id)
  local list = items()
  for i, c in ipairs(list) do if c.id == id then return i end end
  return 1
end

local function layout(vw, vh)
  local cardW = math.min(560, math.floor(vw * 0.78))
  local cardH = math.min(220, math.floor(vh * 0.44))
  local cardX = math.floor((vw - cardW) / 2)
  local cardY = math.floor(vh * 0.34)
  local arrowSize = 56
  local backW, backH = 160, 44
  local backX = math.floor((vw - backW) / 2)
  local backY = math.floor(vh * 0.82)
  local leftX = math.max(8, cardX - arrowSize - 18)
  local rightX = math.min(vw - arrowSize - 8, cardX + cardW + 18)
  local leftRect = { x = leftX, y = cardY + cardH/2 - arrowSize/2, w = arrowSize, h = arrowSize }
  local rightRect = { x = rightX, y = leftRect.y, w = arrowSize, h = arrowSize }
  local cardRect = { x = cardX, y = cardY, w = cardW, h = cardH }
  local backRect = { x = backX, y = backY, w = backW, h = backH }
  return cardRect, leftRect, rightRect, backRect
end

function UICosmetics.enter()
  local selId = Cosmetics.getSelected()
  selection = findIndexById(selId)
  swipe = { startX = nil, startY = nil, tracking = false }
end

function UICosmetics.update(dt)
  -- no-op
end

local function drawCard(r, cosmetic)
  local unlocked = Cosmetics.isUnlocked(cosmetic.id)
  -- card background
  love.graphics.setColor(1,1,1,1)
  love.graphics.rectangle('line', r.x, r.y, r.w, r.h, 12, 12)
  love.graphics.setColor(0.153, 0.953, 1.0, 0.18)
  love.graphics.rectangle('fill', r.x, r.y, r.w, r.h, 12, 12)

  -- preview ship
  local cx = r.x + 28
  local cy = r.y + r.h/2
  local color
  if cosmetic.id == 'rgb_trip' then
    color = rgbTripColor(love.timer.getTime())
  else
    color = cosmetic.color or {1,1,1,1}
  end
  love.graphics.setColor(color)
  local tw = 48
  love.graphics.polygon('fill', cx + 24, cy - 18, cx + 24 - tw/2, cy + 18, cx + 24 + tw/2, cy + 18)

  -- text
  local curId = Cosmetics.getSelected()
  local status
  if unlocked then
    if curId == cosmetic.id then status = "Unlocked • Selected" else status = "Unlocked" end
  else
    status = string.format("Locked • Needs %d", cosmetic.threshold or 0)
  end

  love.graphics.setColor(1,1,1,1)
  love.graphics.setFont(love.graphics.newFont(26))
  love.graphics.print(cosmetic.name or cosmetic.id, r.x + 110, r.y + 28)
  love.graphics.setFont(love.graphics.newFont(18))
  love.graphics.setColor(unlocked and {0.7,1,0.9,1} or {1,0.6,0.6,1})
  love.graphics.print(status, r.x + 110, r.y + 64)
end

function UICosmetics.draw(vw, vh)
  love.graphics.setColor(1,1,1,1)
  love.graphics.setFont(love.graphics.newFont(36))
  love.graphics.printf("Cosmetics", 0, vh * 0.18, vw, 'center')

  local list = items()
  local cardRect, leftRect, rightRect, backRect = layout(vw, vh)
  drawCard(cardRect, list[selection])

  -- arrows
  love.graphics.setColor(1,1,1,1)
  love.graphics.rectangle('line', leftRect.x, leftRect.y, leftRect.w, leftRect.h, 8, 8)
  love.graphics.rectangle('line', rightRect.x, rightRect.y, rightRect.w, rightRect.h, 8, 8)
  love.graphics.setFont(love.graphics.newFont(28))
  love.graphics.printf('<', leftRect.x, leftRect.y + leftRect.h/2 - 18, leftRect.w, 'center')
  love.graphics.printf('>', rightRect.x, rightRect.y + rightRect.h/2 - 18, rightRect.w, 'center')

  -- back button
  love.graphics.setColor(1,1,1,1)
  love.graphics.setFont(love.graphics.newFont(22))
  love.graphics.rectangle('line', backRect.x, backRect.y, backRect.w, backRect.h, 8, 8)
  love.graphics.printf("Back", backRect.x, backRect.y + backRect.h/2 - 12, backRect.w, 'center')

  -- page indicator
  love.graphics.setFont(love.graphics.newFont(14))
  love.graphics.setColor(1,1,1,0.7)
  love.graphics.printf(string.format("%d / %d", selection, #list), 0, backRect.y - 26, vw, 'center')

  -- hint
  love.graphics.setColor(1,1,1,0.7)
  love.graphics.printf("Swipe or use < / > to browse. Tap card or press Enter to select.", 0, vh*0.90, vw, 'center')
end

local function nextItem()
  local n = #items()
  selection = (selection % n) + 1
end

local function prevItem()
  local n = #items()
  selection = (selection - 2 + n) % n + 1
end

function UICosmetics.keypressed(key)
  if key == 'left' or key == 'a' then
    prevItem(); audio.play('ui_click')
  elseif key == 'right' or key == 'd' then
    nextItem(); audio.play('ui_click')
  elseif key == 'escape' then
    audio.play('ui_click'); return 'back'
  elseif key == 'return' or key == 'enter' or key == 'space' then
    audio.play('ui_click')
    local cosmetic = items()[selection]
    if Cosmetics.isUnlocked(cosmetic.id) then
      Cosmetics.select(cosmetic.id)
    else
      audio.play('hit')
    end
  end
  return nil
end

function UICosmetics.pointerPressed(vw, vh, lx, ly)
  local cardRect, leftRect, rightRect, backRect = layout(vw, vh)
  swipe = { startX = lx, startY = ly, tracking = true }
  -- arrows
  if lx >= leftRect.x and lx <= leftRect.x + leftRect.w and ly >= leftRect.y and ly <= leftRect.y + leftRect.h then
    prevItem(); audio.play('ui_click'); return nil
  end
  if lx >= rightRect.x and lx <= rightRect.x + rightRect.w and ly >= rightRect.y and ly <= rightRect.y + rightRect.h then
    nextItem(); audio.play('ui_click'); return nil
  end
  -- back
  if lx >= backRect.x and lx <= backRect.x + backRect.w and ly >= backRect.y and ly <= backRect.y + backRect.h then
    audio.play('ui_click'); return 'back'
  end
  -- tap card selects
  if lx >= cardRect.x and lx <= cardRect.x + cardRect.w and ly >= cardRect.y and ly <= cardRect.y + cardRect.h then
    local cosmetic = items()[selection]
    if Cosmetics.isUnlocked(cosmetic.id) then
      Cosmetics.select(cosmetic.id); audio.play('ui_click')
    else
      audio.play('hit')
    end
  end
  return nil
end

function UICosmetics.pointerMoved(vw, vh, lx, ly)
  if not swipe.tracking or not swipe.startX then return nil end
  -- just track; decision on release
  return nil
end

function UICosmetics.pointerReleased(vw, vh, lx, ly)
  if not swipe.tracking or not swipe.startX then return nil end
  local dx = lx - swipe.startX
  local dy = ly - swipe.startY
  swipe = { startX = nil, startY = nil, tracking = false }
  if math.abs(dx) > 40 and math.abs(dx) > math.abs(dy) then
    if dx < 0 then nextItem() else prevItem() end
    audio.play('ui_click')
  end
  return nil
end

return UICosmetics
