-- Minesweeper Boss: Spatial awareness and planning
-- Waves 40+: Erratic movement + proximity mines with timer detonation
local BossBase = require("src.game.boss.base")
local Bullets = require("src.game.bullets")

local Minesweeper = {}

function Minesweeper.spawnFromConfig(cfg, vw, vh)
  BossBase.setVirtualSize(vw, vh)
  
  local data = BossBase.createBossData(cfg, 140, 60, 2.5)
  data.mines = {}
  data.mineCooldown = 1.5
  data.mineTimer = 0
  data.movementTimer = 0
  data.movementPattern = "erratic"
  data.baseSpeed = 100
  
  BossBase.setData(data)
end

function Minesweeper.exists()
  return BossBase.exists()
end

function Minesweeper.update(dt)
  local data = BossBase.getData()
  if not data then return end
  
  -- Erratic movement pattern
  data.movementTimer = data.movementTimer + dt
  local speedMultiplier = 1.0 + math.sin(data.movementTimer * 3) * 0.5
  
  -- Change direction randomly
  if math.random() < 0.02 then
    data.dir = data.dir * -1
  end
  
  data.x = data.x + data.dir * data.baseSpeed * speedMultiplier * dt
  
  -- Keep within bounds
  if data.x + data.w/2 >= 1280 - 24 then data.dir = -1 end
  if data.x - data.w/2 <= 24 then data.dir = 1 end
  
  -- Vertical movement
  data.y = data.y + math.sin(data.movementTimer * 2) * 50 * dt
  
  -- Update mines
  for i = #data.mines, 1, -1 do
    local mine = data.mines[i]
    mine.timer = mine.timer - dt
    
    if mine.timer <= 0 then
      -- Mine explodes
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
    
    -- Mine body
    love.graphics.setColor(1.0, 0.5, 0.0, 1.0) -- Orange
    love.graphics.circle('fill', mine.x, mine.y, mine.radius)
    
    -- Warning flash when about to explode
    if flashIntensity > 0 then
      love.graphics.setColor(1.0, 1.0, 0.0, flashIntensity * 0.5)
      love.graphics.circle('fill', mine.x, mine.y, mine.radius * 1.5)
    end
    
    -- Timer indicator
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(string.format("%.1f", mine.timer), mine.x - 10, mine.y - 5)
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