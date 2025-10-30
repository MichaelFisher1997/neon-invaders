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
  
  -- Draw connection arms from core to turrets
  love.graphics.setColor(0.3, 0.3, 0.3, 0.8) -- Dark gray arms
  for _, turret in ipairs(data.turrets) do
    local turretRadius = 40
    local turretX = data.x + math.cos(turret.angle) * turretRadius
    local turretY = data.y + math.sin(turret.angle) * turretRadius
    love.graphics.setLineWidth(4)
    love.graphics.line(data.x, data.y, turretX, turretY)
  end
  love.graphics.setLineWidth(1)
  
  -- Draw turrets with detailed design
  for _, turret in ipairs(data.turrets) do
    local turretRadius = 40
    local turretX = data.x + math.cos(turret.angle) * turretRadius
    local turretY = data.y + math.sin(turret.angle) * turretRadius
    
    -- Turret base (hexagonal)
    love.graphics.setColor(0.2, 0.2, 0.2, 1.0) -- Dark base
    local hexPoints = {}
    for i = 0, 5 do
      local angle = i * math.pi / 3
      local px = turretX + math.cos(angle) * 10
      local py = turretY + math.sin(angle) * 10
      table.insert(hexPoints, px)
      table.insert(hexPoints, py)
    end
    love.graphics.polygon('fill', hexPoints)
    
    -- Turret barrel (elongated and detailed)
    love.graphics.setColor(0.6, 0.6, 0.6, 1.0) -- Metal gray
    local barrelLength = 25
    local barrelEndX = turretX + math.cos(turret.angle) * barrelLength
    local barrelEndY = turretY + math.sin(turret.angle) * barrelLength
    
    -- Main barrel
    love.graphics.setLineWidth(8)
    love.graphics.setColor(0.5, 0.5, 0.5, 1.0)
    love.graphics.line(turretX, turretY, barrelEndX, barrelEndY)
    
    -- Barrel tip
    love.graphics.setLineWidth(4)
    love.graphics.setColor(0.8, 0.8, 0.8, 1.0)
    love.graphics.line(barrelEndX - math.cos(turret.angle) * 5, barrelEndY - math.sin(turret.angle) * 5, 
                   barrelEndX, barrelEndY)
    
    -- Turret center (glowing)
    love.graphics.setColor(1.0, 0.8, 0.2, 0.8) -- Yellow glow
    love.graphics.circle('fill', turretX, turretY, 6)
    love.graphics.setColor(1.0, 1.0, 0.5, 1.0) -- Bright center
    love.graphics.circle('fill', turretX, turretY, 3)
  end
  
  -- Draw central core (detailed design)
  local corePulse = math.sin(love.timer.getTime() * 2) * 0.2 + 0.8
  
  -- Outer core ring
  love.graphics.setColor(0.3, 0.3, 0.3, 1.0) -- Dark outer ring
  love.graphics.circle('fill', data.x, data.y, data.w/2)
  
  -- Middle core ring
  love.graphics.setColor(0.6, 0.6, 0.6, 1.0) -- Metal middle ring
  love.graphics.circle('fill', data.x, data.y, data.w/3)
  
  -- Inner core (pulsing)
  love.graphics.setColor(1.0, 0.8, 0.2, corePulse) -- Pulsing yellow
  love.graphics.circle('fill', data.x, data.y, data.w/6)
  
  -- Energy connections (rotating particles)
  for i = 1, 3 do
    local angle = love.timer.getTime() * 1.5 + (i - 1) * 2 * math.pi / 3
    local px = data.x + math.cos(angle) * (data.w/2 + 15)
    local py = data.y + math.sin(angle) * (data.w/2 + 15)
    love.graphics.setColor(1.0, 0.8, 0.2, 0.6) -- Yellow energy
    love.graphics.circle('fill', px, py, 2)
  end
  
  love.graphics.setLineWidth(1)
  
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