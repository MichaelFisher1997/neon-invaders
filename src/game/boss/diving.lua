-- Diving Boss: Introduces movement-based challenge
-- Waves 10-14: Horizontal movement + periodic dive attacks, bomb drops during dives, fast shots when at top
local BossBase = require("src.game.boss.base")
local Bullets = require("src.game.bullets")

local Diving = {}

function Diving.spawnFromConfig(cfg, vw, vh)
  BossBase.setVirtualSize(vw, vh)
  
  local data = BossBase.createBossData(cfg, 140, 60, 1.0)
  data.state = "horizontal" -- "horizontal", "diving", or "floating"
  data.diveTimer = 5.0 -- Time at top before diving (5 seconds)
  data.diveSpeed = 300
  data.floatSpeed = 120 -- Speed for floating back up
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
      -- Don't reset timer here - reset when returning to horizontal
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
    
    -- Reached bottom, start floating back up
    if data.y >= data.bottomY then
      data.state = "floating"
    end
    
  elseif data.state == "floating" then
    -- Slowly float back to top
    data.y = data.y - data.floatSpeed * dt
    
    -- Continue dropping bombs while floating up (less frequent)
    data.bombCooldown = data.bombCooldown - dt
    if data.bombCooldown <= 0 then
      BossBase.aimedShot(data.x, data.y + data.h/2 + 8, 200, 2)
      data.bombCooldown = 0.4
    end
    
    -- Reached top, resume horizontal movement and reset dive timer
    if data.y <= data.topY then
      data.state = "horizontal"
      data.y = data.topY
      data.diveTimer = 5.0 -- Reset to 5 seconds at top
    end
  end
end

function Diving.draw()
  local data = BossBase.getData()
  if not data then return end
  
  -- Draw diving/floating trail effect
  if data.state == "diving" or data.state == "floating" then
    local trailColor = data.state == "diving" and {1.0, 0.5, 0.0, 0.3} or {1.0, 0.7, 0.2, 0.2}
    love.graphics.setColor(trailColor)
    for i = 1, 3 do
      local trailY = data.y - i * 30
      love.graphics.rectangle('fill', data.x - data.w/2, trailY - data.h/2, data.w, data.h, 10, 10)
    end
  end
  
  -- Main boss body (red/orange)
  local color
  if data.state == "diving" then
    color = {1.0, 0.3, 0.0, 1.0}
  elseif data.state == "floating" then
    color = {1.0, 0.7, 0.2, 1.0}
  else
    color = {1.0, 0.5, 0.0, 1.0}
  end
  BossBase.drawRectBoss(color)
  
  -- Draw health bar
  -- BossBase.drawHealthBar() -- Now drawn by HUD
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