-- Phase Boss: Pattern recognition and timing
-- Waves 30-34: Cycles between vulnerable/invulnerable states, different patterns per phase
local BossBase = require("src.game.boss.base")
local Bullets = require("src.game.bullets")

local Phase = {}

function Phase.spawnFromConfig(cfg, vw, vh)
  BossBase.setVirtualSize(vw, vh)
  
  local data = BossBase.createBossData(cfg, 160, 70, 1.8)
  data.phase = 1 -- 1-3 phases
  data.phaseTimer = 4.0
  data.vulnerable = false
  data.phaseColors = {
    {1.0, 0.5, 0.5, 0.5}, -- Red, invulnerable
    {0.5, 1.0, 0.5, 1.0}, -- Green, vulnerable
    {0.5, 0.5, 1.0, 0.5}  -- Blue, invulnerable
  }
  
  BossBase.setData(data)
end

function Phase.exists()
  return BossBase.exists()
end

function Phase.update(dt)
  local data = BossBase.getData()
  if not data then return end
  
  -- Standard horizontal movement
  BossBase.standardMovement(dt, 90)
  
  -- Update phase system
  data.phaseTimer = data.phaseTimer - dt
  if data.phaseTimer <= 0 then
    data.phase = (data.phase % 3) + 1
    data.phaseTimer = 4.0
    data.vulnerable = (data.phase == 2) -- Only vulnerable in phase 2
  end
  
  -- Phase-specific firing patterns
  data.fireCooldown = data.fireCooldown - dt
  if data.fireCooldown <= 0 then
    if data.phase == 1 then
      -- Phase 1: Circular spread + aimed shots
      BossBase.starPattern(data.x, data.y + data.h/2, 8, 280, 0.7)
      if math.random() < 0.4 then
        BossBase.aimedShot(data.x, data.y + data.h/2, 350, 1)
      end
      data.fireCooldown = 1.0
    elseif data.phase == 2 then
      -- Phase 2: Vulnerable - aggressive aimed attacks
      BossBase.shotgunBurst(data.x, data.y + data.h/2, math.pi/3, 4, 380, 1)
      data.fireCooldown = 0.5
    elseif data.phase == 3 then
      -- Phase 3: Spiral pattern + aimed bursts
      local rotation = love.timer.getTime() * 2
      BossBase.spiralPattern(data.x, data.y + data.h/2, 6, 300, 0.8, rotation)
      if math.random() < 0.3 then
        BossBase.aimedShot(data.x, data.y + data.h/2, 400, 1)
      end
      data.fireCooldown = 0.3
    end
  end
end

function Phase.draw()
  local data = BossBase.getData()
  if not data then return end
  
  -- Draw boss with phase-specific appearance
  local color = data.phaseColors[data.phase]
  love.graphics.setColor(unpack(color))
  love.graphics.rectangle('fill', data.x - data.w/2, data.y - data.h/2, data.w, data.h, 10, 10)
  
  -- Draw phase indicator
  love.graphics.setColor(1,1,1,1)
  love.graphics.print("Phase " .. data.phase, data.x - 20, data.y - data.h/2 - 20)
  
  -- Draw health bar
  BossBase.drawHealthBar()
end

function Phase.hit(dmg)
  local data = BossBase.getData()
  if not data then return false end
  
  if data.vulnerable then
    return BossBase.standardHit(dmg)
  else
    return false -- Invulnerable in other phases
  end
end

function Phase.aabb()
  local data = BossBase.getData()
  if not data then return nil end
  
  if data.vulnerable then
    return BossBase.standardAABB()
  else
    return nil -- No collision when invulnerable
  end
end

function Phase.cleanup()
  BossBase.cleanup()
end

return Phase