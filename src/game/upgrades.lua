local Upgrades = {}

local choices = {
  { id='move', label='+15% Move Speed' },
  { id='rate', label='+15% Fire Rate' },
  { id='life', label='+1 Life (max 6)' },
  { id='shield', label='Short Shield (8s)' },
}

local active = { showing=false, selected=1 }

function Upgrades.shouldShowForWave(wave)
  return not (wave % 5 == 0) -- skip on boss wave spawn; simple rule
end

function Upgrades.show()
  active.showing = true
  active.selected = 1
end

function Upgrades.isShowing()
  return active.showing
end

function Upgrades.keypressed(key)
  if not active.showing then return end
  if key=='left' or key=='a' then active.selected = math.max(1, active.selected-1) end
  if key=='right' or key=='d' then active.selected = math.min(#choices, active.selected+1) end
  if key=='tab' then active.selected = (active.selected % #choices) + 1 end
end

function Upgrades.applyTo(player)
  local c = choices[active.selected]
  if not c then return end
  if c.id=='move' then player.speed = player.speed * 1.15 end
  if c.id=='rate' then player.fireRate = math.min(12, player.fireRate * 1.15) end
  if c.id=='life' then player.lives = math.min(6, player.lives + 1) end
  if c.id=='shield' then player.invincibleTimer = math.max(player.invincibleTimer or 0, 8.0) end
  active.showing = false
end

-- Touch support: hit-test cards in the center viewport local space (0..vw, 0..vh)
-- Returns true if a card was hit and selected
function Upgrades.pointerPressed(vw, vh, lx, ly)
  if not active.showing then return false end

  -- Layout params (must match draw())
  local pad = 24
  local gapX, gapY = 20, 20
  local minCardW, maxCardW = 160, 260
  local aspect = 120/260
  -- Use same fonts to get exact heights
  local titleFont = love.graphics.newFont(28)
  local helpFont = love.graphics.newFont(16)

  -- Determine columns that fit
  local bestCols = #choices
  for cols = #choices, 2, -1 do
    local cw = math.floor((vw - 2*pad - (cols-1)*gapX) / cols)
    if cw >= minCardW then bestCols = cols; break end
  end
  local cols = bestCols
  local rows = math.ceil(#choices / cols)
  local cardW = math.min(maxCardW, math.floor((vw - 2*pad - (cols-1)*gapX) / cols))
  local cardH = math.floor(cardW * aspect)

  local gridW = cols*cardW + (cols-1)*gapX
  local startX = math.floor((vw - gridW)/2 + 0.5)

  -- Vertical placement
  local helpY = vh - pad - helpFont:getHeight()
  local gridTop = math.floor(vh*0.32)
  local gridH = rows*cardH + (rows-1)*gapY
  local maxGridTop = helpY - gridH - pad
  if gridTop > maxGridTop then gridTop = math.max(pad + titleFont:getHeight() + 8, maxGridTop) end

  -- Iterate cards and hit-test
  for i, _ in ipairs(choices) do
    local idx = i-1
    local r = math.floor(idx / cols)
    local col = idx % cols
    local x = startX + col*(cardW + gapX)
    local y = gridTop + r*(cardH + gapY)
    if lx >= x and lx <= x + cardW and ly >= y and ly <= y + cardH then
      active.selected = i
      return true
    end
  end

  return false
end

function Upgrades.draw(vw, vh)
  if not active.showing then return end
  -- Dim center viewport only (drawn inside center viewport via caller)
  love.graphics.setColor(0,0,0,0.6)
  love.graphics.rectangle('fill', 0, 0, vw, vh)

  -- Typography
  local titleFont = love.graphics.newFont(28)
  local bodyFont = love.graphics.newFont(18)
  local helpFont = love.graphics.newFont(16)
  love.graphics.setColor(1,1,1,1)
  love.graphics.setFont(titleFont)
  love.graphics.printf('Choose an Upgrade', 0, math.floor(vh*0.20), vw, 'center')

  -- Responsive card layout within center viewport
  local pad = 24
  local gapX, gapY = 20, 20
  local minCardW, maxCardW = 160, 260
  local aspect = 120/260

  -- Determine columns that fit
  local bestCols = #choices
  for cols = #choices, 2, -1 do
    local cw = math.floor((vw - 2*pad - (cols-1)*gapX) / cols)
    if cw >= minCardW then bestCols = cols; break end
  end
  local cols = bestCols
  local rows = math.ceil(#choices / cols)
  local cardW = math.min(maxCardW, math.floor((vw - 2*pad - (cols-1)*gapX) / cols))
  local cardH = math.floor(cardW * aspect)

  local gridW = cols*cardW + (cols-1)*gapX
  local startX = math.floor((vw - gridW)/2 + 0.5)

  -- Vertical placement: title, grid, help
  local helpY = vh - pad - helpFont:getHeight()
  local gridTop = math.floor(vh*0.32)
  local gridH = rows*cardH + (rows-1)*gapY
  -- If grid would collide with help text, push it up
  local maxGridTop = helpY - gridH - pad
  if gridTop > maxGridTop then gridTop = math.max(pad + titleFont:getHeight() + 8, maxGridTop) end

  for i, c in ipairs(choices) do
    local idx = i-1
    local r = math.floor(idx / cols)
    local col = idx % cols
    local x = startX + col*(cardW + gapX)
    local y = gridTop + r*(cardH + gapY)
    love.graphics.setColor(1,1,1, i==active.selected and 1 or 0.7)
    love.graphics.rectangle('line', x, y, cardW, cardH, 10, 10)
    love.graphics.setFont(bodyFont)
    love.graphics.printf(c.label, x+12, y+cardH/2-10, cardW-24, 'center')
    if i==active.selected then
      love.graphics.setColor(0.153, 0.953, 1.0, 0.25)
      love.graphics.rectangle('fill', x, y, cardW, cardH, 10, 10)
    end
  end

  love.graphics.setFont(helpFont)
  love.graphics.setColor(1,1,1,0.85)
  local os = (love.system and love.system.getOS) and love.system.getOS() or ""
  local helpText = (os == "Android" or os == "iOS")
    and 'Tap a card to choose'
    or 'Left/Right (or Tab) to choose, Enter to confirm'
  love.graphics.printf(helpText, 0, helpY, vw, 'center')
end

return Upgrades
