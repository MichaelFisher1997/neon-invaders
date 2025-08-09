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

function Upgrades.draw(vw, vh)
  if not active.showing then return end
  love.graphics.setColor(0,0,0,0.6)
  love.graphics.rectangle('fill', 0, 0, vw, vh)
  love.graphics.setColor(1,1,1,1)
  love.graphics.setFont(love.graphics.newFont(28))
  love.graphics.printf('Choose an Upgrade', 0, vh*0.32, vw, 'center')

  local cardW, cardH = 260, 120
  local gap = 28
  local totalW = #choices*cardW + (#choices-1)*gap
  local startX = (vw - totalW)/2
  for i,c in ipairs(choices) do
    local x = startX + (i-1)*(cardW+gap)
    local y = vh*0.46
    love.graphics.setColor(1,1,1, i==active.selected and 1 or 0.7)
    love.graphics.rectangle('line', x, y, cardW, cardH, 10, 10)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.printf(c.label, x+12, y+cardH/2-10, cardW-24, 'center')
    if i==active.selected then
      love.graphics.setColor(0.153, 0.953, 1.0, 0.25)
      love.graphics.rectangle('fill', x, y, cardW, cardH, 10, 10)
    end
  end

  love.graphics.setFont(love.graphics.newFont(16))
  love.graphics.setColor(1,1,1,0.8)
  love.graphics.printf('Left/Right (or Tab) to choose, Enter to confirm', 0, vh*0.75, vw, 'center')
end

return Upgrades
