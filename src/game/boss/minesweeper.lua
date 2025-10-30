-- Minesweeper Boss: Spatial awareness and planning
-- Waves 40+: Erratic movement + proximity mines with timer detonation
local BossBase = require("src.game.boss.base")
local Bullets = require("src.game.bullets")

local Minesweeper = {}

function Minesweeper.spawnFromConfig(cfg, vw, vh)
  BossBase.setVirtualSize(vw, vh)
  
  local data = BossBase.createBossData(cfg, 140, 60, 2.5)
  data.mines = {}
  data.mineCooldown = 0.2 -- Faster mine dropping for visibility
  data.mineTimer = 0
  data.movementTimer = 0
  data.movementPattern = "sweep" -- Start with sweep
  data.baseSpeed = 150 -- Faster movement for visibility
  data.sweepDirection = 1 -- 1 for right, -1 for left
  data.minesInWave = 0
  data.maxMinesPerWave = 4 -- Drop 3-5 mines per sweep
  data.evasionTimer = 0
  data.evasionDuration = 4.0 -- Zigzag while waiting for mines
  data.startX = vw / 2 -- Remember starting position
  data.targetX = vw - 100 -- Target position for sweep
  data.zigzagTimer = 0
  
  -- Initialize position and direction properly
  data.dir = 1 -- Start moving right
  data.x = vw / 2 -- Start at center
  
  BossBase.setData(data)
  

end

function Minesweeper.exists()
  return BossBase.exists()
end

function Minesweeper.update(dt)
  local data = BossBase.getData()
  if not data then return end
  
  data.movementTimer = data.movementTimer + dt
  
  if data.movementPattern == "sweep" then
    -- Sweep across screen like normal boss movement
    BossBase.standardMovement(dt, data.baseSpeed)
    

    
    -- Drop mines evenly during sweep
    data.mineTimer = data.mineTimer - dt
    if data.mineTimer <= 0 and data.minesInWave < data.maxMinesPerWave then
      local mine = {
        x = data.x,
        y = data.y + data.h/2,
        timer = 3.0 + math.random() * 2.0,
        radius = 15
      }
      table.insert(data.mines, mine)
      data.minesInWave = data.minesInWave + 1
      data.mineTimer = data.mineCooldown
    end
    
    -- Check if sweep is complete (dropped all mines)
    if data.minesInWave >= data.maxMinesPerWave then
      data.movementPattern = "evasion"
      data.evasionTimer = data.evasionDuration
      data.minesInWave = 0
    end
    
  elseif data.movementPattern == "evasion" then
    -- Zigzag movement while waiting for mines to explode
    data.evasionTimer = data.evasionTimer - dt
    data.zigzagTimer = data.zigzagTimer + dt
    
    -- Zigzag pattern
    local zigzagAmount = 60
    local zigzagSpeed = 3
    local xOffset = math.sin(data.zigzagTimer * zigzagSpeed) * zigzagAmount
    
    -- Keep boss in general area but add zigzag
    data.x = data.x + xOffset * dt
    data.y = data.y + math.cos(data.zigzagTimer * 2) * 20 * dt
    
    -- Return to opposite side when evasion ends and all mines have exploded
    if data.evasionTimer <= 0 and #data.mines == 0 then
      data.movementPattern = "sweep"
      data.maxMinesPerWave = 3 + math.random(3) -- 3-5 mines next wave
      
      -- Set target to opposite side
      local BossBase = require("src.game.boss.base")
      local vw, _ = BossBase.getVirtualSize()
      if data.sweepDirection > 0 then
        -- Was going right, now go left
        data.x = vw - 100
        data.sweepDirection = -1
      else
        -- Was going left, now go right  
        data.x = 100
        data.sweepDirection = 1
      end
    end
  end
  
  -- Update mines
  for i = #data.mines, 1, -1 do
    local mine = data.mines[i]
    mine.timer = mine.timer - dt
    
    if mine.timer <= 0 then
      -- Mine explodes with particle effect and shotgun blast
      local Particles = require("src.fx.particles")
      if Particles and Particles.burst then
        Particles.burst(mine.x, mine.y, {1.0, 0.5, 0.0}, 32, 300)
      end
      
      -- Fire shotgun blast from mine explosion
      local pelletCount = 12
      local spreadAngle = math.pi * 2 -- Full 360 degrees
      for i = 0, pelletCount - 1 do
        local angle = (i / pelletCount) * spreadAngle
        local speed = 250 + math.random() * 100
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed
        Bullets.spawn(mine.x, mine.y, vy, 'enemy', 0.8, vx)
      end
      
      table.remove(data.mines, i)
    end
  end
  
  -- Drop mines
  data.mineTimer = data.mineTimer - dt
  if data.mineTimer <= 0 then
    local mine = {
      x = data.x,
      y = data.y + data.h/2,
      timer = 3.0 + math.random() * 2.0, -- Random timer
      radius = 15
    }
    table.insert(data.mines, mine)
    data.mineTimer = data.mineCooldown
  end
  
  -- Also fire directly at player
  data.fireCooldown = data.fireCooldown - dt
  if data.fireCooldown <= 0 then
    local attackType = math.random(3)
    if attackType == 1 then
      -- Fast aimed shot
      BossBase.aimedShot(data.x, data.y + data.h/2, 380, 1)
    elseif attackType == 2 then
      -- Wide shotgun
      BossBase.shotgunBurst(data.x, data.y + data.h/2, math.pi/2, 6, 320, 0.7)
    else
      -- Dense star pattern
      BossBase.starPattern(data.x, data.y + data.h/2, 12, 280, 0.5)
    end
    data.fireCooldown = 0.8
  end
end

function Minesweeper.draw()
  local data = BossBase.getData()
  if not data then return end
  
  -- Draw mines
  for _, mine in ipairs(data.mines) do
    local flashIntensity = mine.timer < 1.0 and (1.0 - mine.timer) or 0.0
    
    -- Mine body with pulsing effect
    local pulse = math.sin(love.timer.getTime() * 4) * 0.2 + 0.8
    love.graphics.setColor(1.0, 0.5, 0.0, pulse) -- Orange with pulse
    love.graphics.circle('fill', mine.x, mine.y, mine.radius)
    
    -- Inner core
    love.graphics.setColor(1.0, 0.8, 0.0, 1.0) -- Bright orange
    love.graphics.circle('fill', mine.x, mine.y, mine.radius * 0.4)
    
    -- Warning flash when about to explode
    if flashIntensity > 0 then
      love.graphics.setColor(1.0, 1.0, 0.0, flashIntensity * 0.5)
      love.graphics.circle('fill', mine.x, mine.y, mine.radius * 1.5)
    end
    
    -- Danger ring (rotating)
    local ringAngle = love.timer.getTime() * 2
    love.graphics.setColor(1.0, 0.2, 0.0, 0.6) -- Red danger ring
    love.graphics.setLineWidth(2)
    love.graphics.circle('line', mine.x, mine.y, mine.radius + 8)
    love.graphics.setLineWidth(1)
  end
  
  -- Draw main boss (orange/yellow)
  love.graphics.setColor(1.0, 0.6, 0.0, 1.0)
  love.graphics.rectangle('fill', data.x - data.w/2, data.y - data.h/2, data.w, data.h, 10, 10)
  
  -- Draw mine-dropping animation
  love.graphics.setColor(1.0, 0.8, 0.0, 0.3)
  love.graphics.rectangle('fill', data.x - data.w/2 - 5, data.y + data.h/2, data.w + 10, 20, 5, 5)
  
  -- Draw health bar
  BossBase.drawHealthBar()
end

function Minesweeper.hit(dmg)
  return BossBase.standardHit(dmg)
end

function Minesweeper.aabb()
  return BossBase.standardAABB()
end

function Minesweeper.cleanup()
  BossBase.cleanup()
end

return Minesweeper