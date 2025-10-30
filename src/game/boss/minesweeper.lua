-- Minesweeper Boss: Spatial awareness and planning
-- Waves 40+: Erratic movement + proximity mines with timer detonation
local BossBase = require("src.game.boss.base")
local Bullets = require("src.game.bullets")

local Minesweeper = {}

function Minesweeper.spawnFromConfig(cfg, vw, vh)
  BossBase.setVirtualSize(vw, vh)
  
  local data = BossBase.createBossData(cfg, 140, 60, 2.5)
  data.mines = {}
  data.mineCooldown = 0.25 -- Mine drop cooldown: 0.2-0.3 seconds
  data.mineTimer = 0
  data.phase = "sweep" -- Current phase: sweep, evasion, explosion, reset
  data.baseSpeed = 180 -- Movement speed: 150-200 pixels/second for visibility
  data.sweepDirection = 1 -- 1 for right, -1 for left
  data.minesInWave = 0
  data.maxMinesPerWave = 4 -- Drop 3-5 mines per sweep
  data.evasionTimer = 0
  data.evasionDuration = 3.5 -- Zigzag while waiting for mines (3-4 seconds)
  data.zigzagTimer = 0
  data.explosionTimer = 0
  data.resetTimer = 0
  
  -- Initialize movement system for full screen sweep
  data.dir = 1 -- Start moving right
  data.x = 50 -- Start at far left for maximum sweep space
  data.y = 140
  data.sweepStartX = 50 -- Track sweep boundaries
  data.sweepEndX = vw - 50
  
  -- Calculate mine spacing for even distribution (ensure all mines fit within sweep area)
  data.sweepDistance = data.sweepEndX - data.sweepStartX
  data.mineSpacing = data.sweepDistance / (data.maxMinesPerWave + 1) -- +1 to ensure mines fit inside bounds
  data.nextMineX = data.sweepStartX + data.mineSpacing -- First mine position
  
  BossBase.setData(data)
end

function Minesweeper.exists()
  return BossBase.exists()
end

function Minesweeper.update(dt)
  local data = BossBase.getData()
  if not data then return end
  
  -- PHASE 1: SWEEP PHASE
  if data.phase == "sweep" then
    -- Drop mines at evenly spaced positions during sweep (only within sweep bounds and only moving right)
    local shouldDropMine = false
    if data.sweepDirection > 0 then -- Moving right
      shouldDropMine = data.minesInWave < data.maxMinesPerWave and 
                      data.x >= data.nextMineX and 
                      data.x <= data.sweepEndX + 10 -- Small buffer to handle step size
    end
    -- Note: Don't place mines while moving left (backtracking)
    
    if shouldDropMine then
      local mine = {
        x = data.x,
        y = data.y + data.h/2,
        timer = 2.0 + math.random() * 2.0, -- 2-4 second fuse
        radius = 15
      }
      table.insert(data.mines, mine)
      data.minesInWave = data.minesInWave + 1
      -- Calculate next mine position based on direction
      data.nextMineX = data.nextMineX + (data.mineSpacing * data.sweepDirection)
    end
    
    -- Store old position for mine placement detection
    local oldX = data.x
    
    -- Custom movement for minesweeper: use sweep boundaries instead of screen boundaries
    data.x = data.x + data.sweepDirection * data.baseSpeed * dt
    
    -- Check for final mine placement if we passed the mine position
    if data.sweepDirection > 0 and data.minesInWave < data.maxMinesPerWave and 
       oldX < data.nextMineX and data.x >= data.nextMineX then
      -- Place mine at the exact position
      local mine = {
        x = data.nextMineX,
        y = data.y + data.h/2,
        timer = 2.0 + math.random() * 2.0,
        radius = 15
      }
      table.insert(data.mines, mine)
      data.minesInWave = data.minesInWave + 1
      data.nextMineX = data.nextMineX + (data.mineSpacing * data.sweepDirection)
    end
    
    -- Reverse direction at sweep boundaries (using center position for mine placement consistency)
    if data.x >= data.sweepEndX then 
      data.sweepDirection = -1 
      data.dir = -1 -- Sync base direction for consistency
    end
    if data.x <= data.sweepStartX then 
      data.sweepDirection = 1 
      data.dir = 1 -- Sync base direction for consistency
    end
    
    -- Check if sweep is complete (dropped all mines)
    if data.minesInWave >= data.maxMinesPerWave then
      data.phase = "evasion"
      data.evasionTimer = data.evasionDuration
      data.zigzagTimer = 0
      -- Don't reset minesInWave - preserve count for next cycle
    end
    
    -- Check if sweep is complete (dropped all mines)
    if data.minesInWave >= data.maxMinesPerWave then
      data.phase = "evasion"
      data.evasionTimer = data.evasionDuration
      data.zigzagTimer = 0
      -- Don't reset minesInWave - preserve count for next cycle
    end
    
  -- PHASE 2: EVASION PHASE  
  elseif data.phase == "evasion" then
    -- Zigzag movement while mines are active
    data.evasionTimer = data.evasionTimer - dt
    data.zigzagTimer = data.zigzagTimer + dt
    
    -- Enhanced zigzag pattern for visibility
    local zigzagAmount = 80 -- Increased for visibility
    local zigzagSpeed = 4 -- Faster zigzag
    local xOffset = math.sin(data.zigzagTimer * zigzagSpeed) * zigzagAmount
    local yOffset = math.cos(data.zigzagTimer * 2.5) * 30
    
    -- Move boss in zigzag pattern
    data.x = data.x + xOffset * dt * 2 -- Amplified for gallery visibility
    data.y = data.y + yOffset * dt
    
    -- Phase transitions: evasion -> explosion -> reset
    if data.evasionTimer <= 0 then
      data.phase = "explosion"
      data.explosionTimer = 2.0 -- Time for explosions to complete
    end
    
  -- PHASE 3: EXPLOSION PHASE
  elseif data.phase == "explosion" then
    -- Mines detonate - movement becomes erratic
    data.explosionTimer = data.explosionTimer - dt
    
    -- Rapid position changes to show explosion activity
    local shakeAmount = 20
    data.x = data.x + (math.random() - 0.5) * shakeAmount * dt
    data.y = data.y + (math.random() - 0.5) * shakeAmount * dt
    
    -- When all mines exploded and explosion time over
    if #data.mines == 0 and data.explosionTimer <= 0 then
      data.phase = "reset"
      data.resetTimer = 1.5 -- Brief reset time
    end
    
  -- PHASE 4: RESET PHASE
  elseif data.phase == "reset" then
    -- Boss moves to opposite side and repeats
    data.resetTimer = data.resetTimer - dt
    
    -- Always start from left going right (as requested by user)
    local newDirection = 1 -- Always move right
    local targetX = data.sweepStartX -- Always start from left side
    
    -- Move to opposite side quickly
    local direction = targetX > data.x and 1 or -1
    data.x = data.x + direction * 200 * dt -- Fast repositioning
    
    -- Begin new sweep when reset complete and boss has reached starting position
    if data.resetTimer <= 0 and math.abs(data.x - targetX) < 5 then
      data.phase = "sweep"
      data.maxMinesPerWave = 2 + math.random(3) -- 3-5 mines for variety
      data.sweepDirection = newDirection -- Update to new direction
      
      -- Let boss move naturally back to left side instead of snapping
      data.dir = newDirection -- Sync movement direction with sweep direction
      
      -- Reset mine count for new wave
      data.minesInWave = 0
      
      -- Recalculate mine spacing for new wave (ensure all mines fit within sweep area)
      data.mineSpacing = data.sweepDistance / (data.maxMinesPerWave + 1) -- +1 to ensure mines fit inside bounds
      data.nextMineX = data.sweepDirection > 0 and data.sweepStartX + data.mineSpacing or data.sweepEndX - data.mineSpacing
    end
  end
  
  -- Update all mines
  for i = #data.mines, 1, -1 do
    local mine = data.mines[i]
    mine.timer = mine.timer - dt
    
    if mine.timer <= 0 then
      -- Mine explodes with shotgun blasts
      local Particles = require("src.fx.particles")
      if Particles and Particles.burst then
        Particles.burst(mine.x, mine.y, {1.0, 0.5, 0.0}, 32, 300)
      end
      
      -- Fire shotgun blast with 12 pellets in 360-degree pattern
      local pelletCount = 12
      local spreadAngle = math.pi * 2 -- Full 360 degrees
      for i = 0, pelletCount - 1 do
        local angle = (i / pelletCount) * spreadAngle
        local speed = 250 + math.random() * 100 -- 250-350 with variation
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed
        Bullets.spawn(mine.x, mine.y, vy, 'enemy', 0.8, vx)
      end
      
      table.remove(data.mines, i)
    end
  end
  
  -- Standard boss firing (reduced for clarity in gallery)
  data.fireCooldown = data.fireCooldown - dt
  if data.fireCooldown <= 0 and data.phase ~= "explosion" then -- Don't fire during explosion
    -- Simple straight shots to avoid cluttering gallery view
    Bullets.spawn(data.x, data.y + data.h/2, 380, 'enemy', 1)
    data.fireCooldown = 1.2 -- Slower firing for gallery visibility
  end
end

function Minesweeper.draw()
  local data = BossBase.getData()
  if not data then return end
  
  -- Draw mines with enhanced visual effects
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
    
    -- Red danger rings (rotating)
    local ringAngle = love.timer.getTime() * 3
    love.graphics.setColor(1.0, 0.2, 0.0, 0.8) -- Red danger ring
    love.graphics.setLineWidth(2)
    love.graphics.circle('line', mine.x, mine.y, mine.radius + 6)
    love.graphics.setLineWidth(1)
    
    -- Additional inner ring
    love.graphics.setColor(1.0, 0.0, 0.0, 0.6)
    love.graphics.circle('line', mine.x, mine.y, mine.radius + 12)
  end
  
  -- Draw main boss with enhanced appearance
  -- Base body
  love.graphics.setColor(1.0, 0.6, 0.0, 1.0)
  love.graphics.rectangle('fill', data.x - data.w/2, data.y - data.h/2, data.w, data.h, 10, 10)
  
  -- Phase indicator on boss
  if data.phase == "sweep" then
    love.graphics.setColor(0.0, 1.0, 0.0, 0.3) -- Green for sweep
  elseif data.phase == "evasion" then
    love.graphics.setColor(1.0, 1.0, 0.0, 0.3) -- Yellow for evasion
  elseif data.phase == "explosion" then
    love.graphics.setColor(1.0, 0.0, 0.0, 0.3) -- Red for explosion
  else
    love.graphics.setColor(0.0, 0.0, 1.0, 0.3) -- Blue for reset
  end
  love.graphics.rectangle('fill', data.x - data.w/2 - 2, data.y - data.h/2 - 2, data.w + 4, data.h + 4, 12, 12)
  
  -- Mine-dropping animation
  love.graphics.setColor(1.0, 0.8, 0.0, 0.4)
  love.graphics.rectangle('fill', data.x - data.w/2 - 5, data.y + data.h/2, data.w + 10, 25, 5, 5)
  
  -- Health bar
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