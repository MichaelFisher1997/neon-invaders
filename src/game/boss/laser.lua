-- Laser Boss: Precise timing and positioning
-- Waves 20-24: Charges laser sweeps across screen, mini-bursts when charging
local BossBase = require("src.game.boss.base")
local Bullets = require("src.game.bullets")

local Laser = {}

function Laser.spawnFromConfig(cfg, vw, vh)
  BossBase.setVirtualSize(vw, vh)
  
  local data = BossBase.createBossData(cfg, 150, 70, 1.4)
  data.state = "charging" -- "charging", "firing", "cooldown"
  data.chargeTimer = 2.0
  data.laserAngle = 0
  data.laserSweepSpeed = 1.5
  data.laserLength = 800
  data.laserWidth = 8
  data.miniBurstCooldown = 0
  
  BossBase.setData(data)
end

function Laser.exists()
  return BossBase.exists()
end

function Laser.update(dt)
  local data = BossBase.getData()
  if not data then return end
  
  -- Standard horizontal movement
  BossBase.standardMovement(dt, 60)
  
  -- Update laser state machine
  if data.state == "charging" then
    data.chargeTimer = data.chargeTimer - dt
    
    -- Fire mini-bursts while charging
    data.miniBurstCooldown = data.miniBurstCooldown - dt
    if data.miniBurstCooldown <= 0 then
      -- Mix of patterns while charging
      local burstType = math.random(3)
      if burstType == 1 then
        -- Small burst of bullets
        for i = -1, 1 do
          Bullets.spawn(data.x + i*20, data.y + data.h/2, 250, 'enemy', 0.5)
        end
      elseif burstType == 2 then
        -- Aimed shot
        BossBase.aimedShot(data.x, data.y + data.h/2, 300, 0.8)
      else
        -- Small star
        BossBase.starPattern(data.x, data.y + data.h/2, 4, 220, 0.4)
      end
      data.miniBurstCooldown = 0.12
    end
    
    if data.chargeTimer <= 0 then
      data.state = "firing"
      data.laserAngle = -math.pi/3 -- Start from left
      data.chargeTimer = 3.0 -- Duration of laser sweep
    end
    
  elseif data.state == "firing" then
    -- Sweep laser across screen
    data.laserAngle = data.laserAngle + data.laserSweepSpeed * dt
    data.chargeTimer = data.chargeTimer - dt
    
    if data.chargeTimer <= 0 then
      data.state = "cooldown"
      data.chargeTimer = 2.0
    end
    
  elseif data.state == "cooldown" then
    data.chargeTimer = data.chargeTimer - dt
    
    if data.chargeTimer <= 0 then
      data.state = "charging"
      data.chargeTimer = 2.0
    end
  end
end

function Laser.draw()
  local data = BossBase.getData()
  if not data then return end
  
  -- Draw laser beam when firing
  if data.state == "firing" then
    local endX = data.x + math.cos(data.laserAngle) * data.laserLength
    local endY = data.y + math.sin(data.laserAngle) * data.laserLength
    
    -- Laser glow effect
    love.graphics.setColor(0, 1, 1, 0.3)
    love.graphics.setLineWidth(data.laserWidth * 3)
    love.graphics.line(data.x, data.y, endX, endY)
    
    -- Main laser beam
    love.graphics.setColor(0, 0.8, 1, 1.0)
    love.graphics.setLineWidth(data.laserWidth)
    love.graphics.line(data.x, data.y, endX, endY)
    love.graphics.setLineWidth(1)
  end
  
  -- Draw charge-up glow when charging
  if data.state == "charging" then
    local chargeRatio = 1 - (data.chargeTimer / 2.0)
    love.graphics.setColor(0, 0.8, 1, chargeRatio * 0.5)
    love.graphics.rectangle('fill', data.x - data.w/2 - 10, data.y - data.h/2 - 10, data.w + 20, data.h + 20, 15, 15)
  end
  
  -- Main boss body (blue/cyan)
  local color = data.state == "charging" and {0.2, 0.6, 1.0, 1.0} or {0.0, 0.8, 1.0, 1.0}
  BossBase.drawRectBoss(color)
  
  -- Draw health bar
  -- BossBase.drawHealthBar() -- Now drawn by HUD
end

function Laser.hit(dmg)
  return BossBase.standardHit(dmg)
end

function Laser.aabb()
  return BossBase.standardAABB()
end

function Laser.getLaserData()
  return BossBase.getData()
end

function Laser.cleanup()
  BossBase.cleanup()
end

return Laser