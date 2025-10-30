-- Summoner Boss: Crowd control and prioritization
-- Waves 25-29: Spawns mini-enemies periodically, indirect via summoned minions
local BossBase = require("src.game.boss.base")
local Bullets = require("src.game.bullets")

local Summoner = {}

function Summoner.spawnFromConfig(cfg, vw, vh)
  BossBase.setVirtualSize(vw, vh)
  
  local data = BossBase.createBossData(cfg, 140, 60, 1.6)
  data.spawnTimer = 3.0
  data.spawnCooldown = 3.0
  data.maxMinions = 6
  data.minions = {}
  
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
  
  -- Update minions
  for i = #data.minions, 1, -1 do
    local minion = data.minions[i]
    minion.y = minion.y + minion.speed * dt
    minion.x = minion.x + math.sin(minion.time * 3) * 50 * dt
    minion.time = minion.time + dt
    
    -- Remove minions that go off screen
    if minion.y > 720 then
      table.remove(data.minions, i)
    end
  end
  
  -- Spawn new minions
  data.spawnTimer = data.spawnTimer - dt
  if data.spawnTimer <= 0 and #data.minions < data.maxMinions then
    local minion = {
      x = data.x + (math.random() - 0.5) * 100,
      y = data.y + data.h/2,
      speed = 80 + math.random() * 40,
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
  
  -- Draw minions
  for _, minion in ipairs(data.minions) do
    love.graphics.setColor(0.6, 0.2, 0.8, 1.0) -- Dark purple
    love.graphics.rectangle('fill', minion.x - 10, minion.y - 10, 20, 20, 3, 3)
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