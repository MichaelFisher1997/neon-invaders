-- Turret Boss: 360-degree threat management
-- Waves 35-39: Central core with 4 rotating turrets, independent turret firing patterns
local BossBase = require("src.game.boss.base")
local Bullets = require("src.game.bullets")

local Turret = {}

function Turret.spawnFromConfig(cfg, vw, vh)
  BossBase.setVirtualSize(vw, vh)
  
  local data = BossBase.createBossData(cfg, 120, 120, 2.0)
  data.turrets = {
    {angle = 0, fireCooldown = 0, fireRate = 2.5},
    {angle = math.pi/2, fireCooldown = 0, fireRate = 2.5},
    {angle = math.pi, fireCooldown = 0, fireRate = 2.5},
    {angle = 3*math.pi/2, fireCooldown = 0, fireRate = 2.5}
  }
  data.rotationSpeed = 1.0
  
  BossBase.setData(data)
end

function Turret.exists()
  return BossBase.exists()
end

function Turret.update(dt)
  local data = BossBase.getData()
  if not data then return end
  
  -- Standard horizontal movement (slower)
  BossBase.standardMovement(dt, 50)
  
  -- Rotate turrets
  for _, turret in ipairs(data.turrets) do
    turret.angle = turret.angle + data.rotationSpeed * dt
    
    -- Update firing
    turret.fireCooldown = turret.fireCooldown - dt
    if turret.fireCooldown <= 0 then
      -- Fire from turret position
      local turretRadius = 40
      local turretX = data.x + math.cos(turret.angle) * turretRadius
      local turretY = data.y + math.sin(turret.angle) * turretRadius
      
      -- Mix of firing patterns
      local fireType = math.random(3)
      if fireType == 1 then
        -- Standard outward shot
        local bulletSpeed = 300
        local vx = math.cos(turret.angle) * bulletSpeed
        local vy = math.sin(turret.angle) * bulletSpeed
        Bullets.spawn(turretX, turretY, bulletSpeed, 'enemy', 1)
      elseif fireType == 2 then
        -- Aimed shot from turret
        BossBase.aimedShot(turretX, turretY, 350, 1)
      else
        -- Small burst from turret
        local spreadAngle = math.pi/8
        for i = -1, 1 do
          local angle = turret.angle + i * spreadAngle
          local speed = 280
          local vx = math.cos(angle) * speed
          local vy = math.sin(angle) * speed
          Bullets.spawn(turretX, turretY, speed, 'enemy', 0.8)
        end
      end
      
      turret.fireCooldown = 1 / turret.fireRate
    end
  end
end

function Turret.draw()
  local data = BossBase.getData()
  if not data then return end
  
  -- Draw turrets
  for _, turret in ipairs(data.turrets) do
    local turretRadius = 40
    local turretX = data.x + math.cos(turret.angle) * turretRadius
    local turretY = data.y + math.sin(turret.angle) * turretRadius
    
    -- Turret barrel
    love.graphics.setColor(0.6, 0.6, 0.6, 1.0) -- Metal gray
    love.graphics.rectangle('fill', turretX - 15, turretY - 8, 30, 16, 3, 3)
    
    -- Turret base
    love.graphics.setColor(0.4, 0.4, 0.4, 1.0)
    love.graphics.circle('fill', turretX, turretY, 12)
  end
  
  -- Draw central core
  love.graphics.setColor(0.5, 0.5, 0.5, 1.0) -- Metal gray
  love.graphics.rectangle('fill', data.x - data.w/2, data.y - data.h/2, data.w, data.h, 10, 10)
  
  -- Draw rotating indicator
  love.graphics.setColor(1.0, 0.8, 0.0, 0.8) -- Orange indicator
  love.graphics.circle('line', data.x, data.y, 50)
  
  -- Draw health bar
  BossBase.drawHealthBar()
end

function Turret.hit(dmg)
  return BossBase.standardHit(dmg)
end

function Turret.aabb()
  return BossBase.standardAABB()
end

function Turret.cleanup()
  BossBase.cleanup()
end

return Turret