-- Diving Boss: Introduces movement-based challenge
-- Waves 10-14: Horizontal movement + periodic dive attacks, bomb drops during dives, fast shots when at top
local BossBase = require("src.game.boss.base")
local Bullets = require("src.game.bullets")

local Diving = {}

function Diving.spawnFromConfig(cfg, vw, vh)
  BossBase.setVirtualSize(vw, vh)
  
  local data = BossBase.createBossData(cfg, 140, 60, 1.0)
  data.state = "horizontal" -- "horizontal" or "diving"
  data.diveTimer = 3.0 -- Time between dives
  data.diveSpeed = 300
  data.horizontalSpeed = 80
  data.topY = 100
  data.bottomY = 500
  data.bombCooldown = 0
  
  BossBase.setData(data)
end

function Diving.exists()
  return BossBase.exists()
end

function Diving.update(dt)
  local data = BossBase.getData()
  if not data then return end
  
  data.diveTimer = data.diveTimer - dt
  
  if data.state == "horizontal" then
    -- Standard horizontal movement
    BossBase.standardMovement(dt, data.horizontalSpeed)
    
    -- Fire fast shots when at top
    data.fireCooldown = data.fireCooldown - dt
    if data.fireCooldown <= 0 then
      local attackType = math.random(3)
      if attackType == 1 then
        -- Fast aimed shot
        BossBase.aimedShot(data.x, data.y + data.h/2 + 8, 450, 1)
      elseif attackType == 2 then
        -- Quick shotgun
        BossBase.shotgunBurst(data.x, data.y + data.h/2 + 8, math.pi/4, 3, 400, 0.8)
      else
        -- Double aimed shot
        BossBase.aimedShot(data.x - 15, data.y + data.h/2 + 8, 420, 1)
        BossBase.aimedShot(data.x + 15, data.y + data.h/2 + 8, 420, 1)
      end
      data.fireCooldown = 0.4
    end
    
    -- Start dive when timer expires
    if data.diveTimer <= 0 then
      data.state = "diving"
      data.diveTimer = 4.0 -- Reset for next cycle
    end
    
  elseif data.state == "diving" then
    -- Diving movement
    data.y = data.y + data.diveSpeed * dt
    
      -- Drop bombs during dive
      data.bombCooldown = data.bombCooldown - dt
      if data.bombCooldown <= 0 then
        -- Drop bombs aimed at player's predicted position
        BossBase.aimedShot(data.x, data.y + data.h/2 + 8, 250, 2)
        data.bombCooldown = 0.2
      end
    
    -- Reached bottom, return to top
    if data.y >= data.bottomY then
      data.state = "horizontal"
      data.y = data.topY
    end
  end
end

function Diving.draw()
  local data = BossBase.getData()
  if not data then return end
  
  -- Draw diving trail effect when diving
  if data.state == "diving" then
    love.graphics.setColor(1.0, 0.5, 0.0, 0.3) -- Orange trail
    for i = 1, 3 do
      local trailY = data.y - i * 30
      love.graphics.rectangle('fill', data.x - data.w/2, trailY - data.h/2, data.w, data.h, 10, 10)
    end
  end
  
  -- Main boss body (red/orange)
  local color = data.state == "diving" and {1.0, 0.3, 0.0, 1.0} or {1.0, 0.5, 0.0, 1.0}
  BossBase.drawRectBoss(color)
  
  -- Draw health bar
  BossBase.drawHealthBar()
end

function Diving.hit(dmg)
  return BossBase.standardHit(dmg)
end

function Diving.aabb()
  return BossBase.standardAABB()
end

function Diving.cleanup()
  BossBase.cleanup()
end

return Diving