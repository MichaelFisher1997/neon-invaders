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
    
    -- Get player position for drift direction (not active chasing)
    local px, py = Player.x, Player.y
    
    -- Always move down
    minion.y = minion.y + data.minionSpeed * dt
    
    -- Calculate drift direction to player (only if player exists and not too far)
    if px and py then
      local dx = px - minion.x
      local dy = py - minion.y
      local distance = math.sqrt(dx*dx + dy*dy)
      
      -- Only drift if player is within reasonable distance (400 pixels)
      if distance < 400 then
        -- Calculate drift component (limited sideways movement)
        local driftStrength = 0.3 -- Only 30% of speed goes toward player
        local dirX = (dx / distance) * data.minionSpeed * driftStrength * dt
        
        -- Apply drift (limited sideways movement)
        minion.x = minion.x + dirX
      end
    end
    
    -- Check collision with player
    if px and py then
      local playerWidth = 40
      local playerHeight = 18
      if minion.x > px - playerWidth/2 and minion.x < px + playerWidth/2 and
         minion.y > py - playerHeight/2 and minion.y < py + playerHeight/2 then
        -- Hit player, explode
        local Particles = require("src.fx.particles")
        if Particles and Particles.burst then
          Particles.burst(minion.x, minion.y, {1.0, 0.5, 1.0}, 24, 200)
        end
        table.remove(data.minions, i)
        return -- Skip removal check since we already removed it
      end
    end
    
    -- Check collision with player bullets
    local Bullets = require("src.game.bullets")
    Bullets.eachActive(function(bullet)
      if bullet.from == 'player' and bullet.active then
        -- Simple AABB collision
        if math.abs(minion.x - bullet.x) < 12 and math.abs(minion.y - bullet.y) < 12 then
          -- Hit by bullet, explode
          local Particles = require("src.fx.particles")
          if Particles and Particles.burst then
            Particles.burst(minion.x, minion.y, {1.0, 0.5, 1.0}, 16, 150)
          end
          bullet.active = false -- Remove bullet
          table.remove(data.minions, i)
          return -- Skip removal check since we already removed it
        end
      end
    end)
    
    minion.time = minion.time + dt
    
    -- Remove minions that go off screen (explode at bottom)
    local BossBase = require("src.game.boss.base")
    local _, vh = BossBase.getVirtualSize()
    if minion.y > vh then
      -- Create explosion effect at bottom
      local Particles = require("src.fx.particles")
      if Particles and Particles.burst then
        Particles.burst(minion.x, vh - 20, {1.0, 0.5, 1.0}, 24, 200)
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