-- Summoner Boss: Crowd control and prioritization
-- Waves 25-29: Spawns mini-enemies periodically, indirect via summoned minions
local BossBase = require("src.game.boss.base")
local Bullets = require("src.game.bullets")

local Summoner = {}

function Summoner.spawnFromConfig(cfg, vw, vh)
  BossBase.setVirtualSize(vw, vh)
  
  local data = BossBase.createBossData(cfg, 140, 60, 1.6)
  data.spawnTimer = 2.0
  data.spawnCooldown = 4.0
  data.maxMinions = 1 -- Only one minion at a time
  data.minions = {}
  data.minionSpeed = 120 -- Speed for homing missiles
  
  BossBase.setData(data)
end

function Summoner.exists()
  return BossBase.exists()
end

function Summoner.update(dt)
  local data = BossBase.getData()
  if not data then return end
  
  -- Standard horizontal movement
  BossBase.standardMovement(dt, 70)
  
  -- Update minions (homing missiles)
  local Player = require("src.game.player")
  for i = #data.minions, 1, -1 do
    local minion = data.minions[i]
    
    -- Get player position for homing
    local px, py = Player.x, Player.y
    
    -- Calculate direction to player (only if player exists and not too far)
    if px and py then
      local dx = px - minion.x
      local dy = py - minion.y
      local distance = math.sqrt(dx*dx + dy*dy)
      
      -- Only home if player is within reasonable distance (400 pixels)
      if distance < 400 then
        -- Normalize direction and apply speed
        local dirX = (dx / distance) * data.minionSpeed * dt
        local dirY = (dy / distance) * data.minionSpeed * dt
        
        -- Move down and toward player (no sideways movement if too far)
        minion.x = minion.x + dirX
        minion.y = minion.y + dirY
      else
        -- Player too far, just move down
        minion.y = minion.y + data.minionSpeed * dt
      end
    else
      -- No player, just move down
      minion.y = minion.y + data.minionSpeed * dt
    end
    
    minion.time = minion.time + dt
    
    -- Remove minions that go off screen (explode at bottom)
    if minion.y > vh then
      -- Create explosion effect at bottom
      local Particles = require("src.fx.particles")
      if Particles and Particles.createExplosion then
        Particles.createExplosion(minion.x, vh - 20, 0.5)
      end
      table.remove(data.minions, i)
    end
  end
  
  -- Spawn new homing minions (one at a time)
  data.spawnTimer = data.spawnTimer - dt
  if data.spawnTimer <= 0 and #data.minions < data.maxMinions then
    local minion = {
      x = data.x,
      y = data.y + data.h/2,
      time = 0,
      hp = 1
    }
    table.insert(data.minions, minion)
    data.spawnTimer = data.spawnCooldown
  end
  
  -- Boss also fires directly at player
  data.fireCooldown = data.fireCooldown - dt
  if data.fireCooldown <= 0 then
    local attackType = math.random(3)
    if attackType == 1 then
      -- Aimed shot
      BossBase.aimedShot(data.x, data.y + data.h/2, 320, 1)
    elseif attackType == 2 then
      -- Shotgun burst
      BossBase.shotgunBurst(data.x, data.y + data.h/2, math.pi/4, 4, 300, 0.8)
    else
      -- Star pattern
      BossBase.starPattern(data.x, data.y + data.h/2, 6, 250, 0.6)
    end
    data.fireCooldown = 1.5
  end
end

function Summoner.draw()
  local data = BossBase.getData()
  if not data then return end
  
  -- Draw homing minions (missile-like appearance)
  for _, minion in ipairs(data.minions) do
    -- Draw missile trail
    love.graphics.setColor(0.8, 0.3, 1.0, 0.4) -- Light purple trail
    love.graphics.rectangle('fill', minion.x - 3, minion.y - 15, 6, 15, 2, 2)
    
    -- Draw missile body
    love.graphics.setColor(0.6, 0.2, 0.8, 1.0) -- Dark purple
    love.graphics.rectangle('fill', minion.x - 6, minion.y - 8, 12, 16, 3, 3)
    
    -- Draw glowing tip
    love.graphics.setColor(1.0, 0.5, 1.0, 1.0) -- Bright purple tip
    love.graphics.rectangle('fill', minion.x - 2, minion.y - 8, 4, 4, 1, 1)
  end
  
  -- Draw main boss (dark purple with summoning effect)
  local glowIntensity = math.sin(love.timer.getTime() * 2) * 0.3 + 0.7
  love.graphics.setColor(0.4, 0.1, 0.6, glowIntensity * 0.3)
  love.graphics.rectangle('fill', data.x - data.w/2 - 15, data.y - data.h/2 - 15, data.w + 30, data.h + 30, 15, 15)
  
  love.graphics.setColor(0.6, 0.2, 0.8, 1.0)
  love.graphics.rectangle('fill', data.x - data.w/2, data.y - data.h/2, data.w, data.h, 10, 10)
  
  -- Draw health bar
  BossBase.drawHealthBar()
end

function Summoner.hit(dmg)
  return BossBase.standardHit(dmg)
end

function Summoner.aabb()
  return BossBase.standardAABB()
end

function Summoner.getMinions()
  local data = BossBase.getData()
  if not data then return {} end
  return data.minions
end

function Summoner.cleanup()
  BossBase.cleanup()
end

return Summoner