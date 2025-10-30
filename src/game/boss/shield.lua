-- Shield Boss: Teaches players to break through defenses
-- Waves 5-9: 3 shield segments protect core, slow spread shots when shields down
local BossBase = require("src.game.boss.base")
local Bullets = require("src.game.bullets")

local Shield = {}

function Shield.spawnFromConfig(cfg, vw, vh)
  BossBase.setVirtualSize(vw, vh)
  
  local data = BossBase.createBossData(cfg, 180, 80, 0.8)
  data.shieldHealth = {100, 100, 100} -- 3 shield segments
  data.shieldMaxHealth = {100, 100, 100}
  data.shieldPositions = {
    {x = -60, y = -40}, 
    {x = 0, y = -45}, 
    {x = 60, y = -40}
  }
  data.shieldsDown = false
  
  BossBase.setData(data)
end

function Shield.exists()
  return BossBase.exists()
end

function Shield.update(dt)
  local data = BossBase.getData()
  if not data then return end
  
  -- Standard horizontal movement
  BossBase.standardMovement(dt, 100)
  
  -- Update shields - they disappear when health reaches 0
  local shieldsAlive = 0
  for i = 1, 3 do
    if data.shieldHealth[i] > 0 then
      shieldsAlive = shieldsAlive + 1
    end
  end
  
  data.shieldsDown = (shieldsAlive == 0)
  
  -- Fire behavior based on shield status
  data.fireCooldown = data.fireCooldown - dt
  
  if data.fireCooldown <= 0 then
    if data.shieldsDown then
      -- Desperate attacks when shields are down
      local attackType = math.random(3)
      if attackType == 1 then
        -- Aimed shot at player
        BossBase.aimedShot(data.x, data.y + data.h/2, 400, 1)
      elseif attackType == 2 then
        -- Shotgun burst
        BossBase.shotgunBurst(data.x, data.y + data.h/2, math.pi/3, 5, 350, 0.8)
      else
        -- Star pattern
        BossBase.starPattern(data.x, data.y + data.h/2, 8, 300, 0.6)
      end
      data.fireCooldown = 0.8 -- Faster rate when shields down
    else
      -- Occasional aimed shots even when shields up (less frequent)
      if math.random() < 0.3 then
        BossBase.aimedShot(data.x, data.y + data.h/2, 320, 1)
      end
      data.fireCooldown = 1.2
    end
  end
end

function Shield.draw()
  local data = BossBase.getData()
  if not data then return end
  
  -- Draw shield segments
  for i = 1, 3 do
    local shieldData = data.shieldPositions[i]
    local shieldX = data.x + shieldData.x
    local shieldY = data.y + shieldData.y
    
    if data.shieldHealth[i] > 0 then
      -- Draw shield (glowing cyan) - 3x larger
      love.graphics.setColor(0, 1, 1, 0.8)
      love.graphics.rectangle('fill', shieldX - 75, shieldY - 45, 150, 90, 8, 8)
      
      -- Shield health indicator
      local shieldRatio = data.shieldHealth[i] / data.shieldMaxHealth[i]
      love.graphics.setColor(0, 0.8, 0.8, 1)
      love.graphics.rectangle('fill', shieldX - 60, shieldY + 60, 120 * shieldRatio, 6)
    end
  end
  
  -- Draw main boss body (purple) - only visible when shields are down
  if data.shieldsDown then
    love.graphics.setColor(0.541, 0.169, 0.886, 1.0)
    love.graphics.rectangle('fill', data.x - data.w/2, data.y - data.h/2, data.w, data.h, 10, 10)
  else
    -- Draw core behind shields (dimmed)
    love.graphics.setColor(0.541, 0.169, 0.886, 0.3)
    love.graphics.rectangle('fill', data.x - data.w/2, data.y - data.h/2, data.w, data.h, 10, 10)
  end
  
  -- Draw health bar
  BossBase.drawHealthBar()
end

function Shield.hit(dmg)
  local data = BossBase.getData()
  if not data then return false end
  
  -- Check if shields are hit first (hit shields in order)
  for i = 1, 3 do
    if data.shieldHealth[i] > 0 then
      data.shieldHealth[i] = data.shieldHealth[i] - (dmg or 1)
      if data.shieldHealth[i] < 0 then data.shieldHealth[i] = 0 end
      return false -- Shield absorbed the hit
    end
  end
  
  -- If no shields left, hit the main boss
  return BossBase.standardHit(dmg)
end

function Shield.aabb()
  local data = BossBase.getData()
  if not data then return nil end
  
  -- Always return collision box, but shields absorb damage
  return BossBase.standardAABB()
end

function Shield.cleanup()
  BossBase.cleanup()
end

return Shield