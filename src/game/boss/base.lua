-- Base boss framework for shared functionality
local Bullets = require("src.game.bullets")

local BossBase = {}

local VIRTUAL_WIDTH, VIRTUAL_HEIGHT = 1280, 720
local currentBossData = nil

function BossBase.setVirtualSize(vw, vh)
  VIRTUAL_WIDTH, VIRTUAL_HEIGHT = vw or 1280, vh or 720
end

function BossBase.getVirtualSize()
  return VIRTUAL_WIDTH, VIRTUAL_HEIGHT
end

function BossBase.setData(data)
  currentBossData = data
end

function BossBase.getData()
  return currentBossData
end

function BossBase.exists()
  return currentBossData ~= nil
end

function BossBase.cleanup()
  currentBossData = nil
end

-- Calculate boss health based on wave with progressive difficulty
function BossBase.calculateHealth(wave, multiplier)
  local baseHP = 20 + 6 * wave
  local bonusHP = 2 * math.floor(wave / 10)
  local health = (baseHP + bonusHP) * 3 * multiplier
  return math.floor(health)
end

-- Standard boss hit handler
function BossBase.standardHit(dmg)
  if not currentBossData then return false end
  currentBossData.hp = currentBossData.hp - (dmg or 1)
  if currentBossData.hp <= 0 then
    currentBossData = nil
    return true
  end
  return false
end

-- Get standard collision box
function BossBase.standardAABB()
  if not currentBossData then return nil end
  local data = currentBossData
  return data.x - data.w/2, data.y - data.h/2, data.w, data.h
end

-- Default draw function for simple rectangular bosses
function BossBase.drawRectBoss(color, outlineColor)
  if not currentBossData then return end
  
  local data = currentBossData
  love.graphics.setColor(unpack(color))
  love.graphics.rectangle('fill', data.x - data.w/2, data.y - data.h/2, data.w, data.h, 10, 10)
  
  if outlineColor then
    love.graphics.setColor(unpack(outlineColor))
    love.graphics.rectangle('line', data.x - data.w/2, data.y - data.h/2, data.w, data.h, 10, 10)
  end
end

-- Standard health bar display
function BossBase.drawHealthBar()
  if not currentBossData then return end
  
  local data = currentBossData
  local barW = 240
  local ratio = data.hp / data.hpMax
  
  love.graphics.setColor(1,1,1,1)
  love.graphics.rectangle('line', VIRTUAL_WIDTH/2 - barW/2, 32, barW, 10)
  
  love.graphics.setColor(1.0, 0.182, 0.651, 1.0)
  love.graphics.rectangle('fill', VIRTUAL_WIDTH/2 - barW/2 + 2, 34, (barW-4) * math.max(0, ratio), 6)
end

-- Standard movement (horizontal back and forth)
function BossBase.standardMovement(dt, speed)
  if not currentBossData then return end
  
  local data = currentBossData
  data.x = data.x + data.dir * speed * dt
  
  if data.x + data.w/2 >= VIRTUAL_WIDTH - 24 then 
    data.dir = -1 
  end
  if data.x - data.w/2 <= 24 then 
    data.dir = 1 
  end
end

-- Create boss data with common properties
function BossBase.createBossData(cfg, w, h, multiplier)
  local hpMax = BossBase.calculateHealth(cfg.wave, multiplier)
  
  return {
    x = VIRTUAL_WIDTH / 2,
    y = 140,
    w = w or 160,
    h = h or 64,
    dir = 1,
    speed = 120,
    hpMax = hpMax,
    hp = hpMax,
    fireCooldown = 0,
    fireRate = 2.0 + 0.3 * math.floor(cfg.wave / 5),
    shields = {},
    minions = {},
    -- Additional properties for specific boss types
    state = "normal",
    stateTimer = 0,
    segments = {},
    turrets = {},
    mines = {},
    chargeTimer = 0,
    vulnerable = true
  }
end

-- Helper attack patterns
function BossBase.aimedShot(bossX, bossY, speed, damage)
  local Player = require("src.game.player")
  local px, py = Player.x, Player.y
  
  -- Check if player position is available (not in gallery/menu)
  if not px or not py then
    -- Default to shooting straight down when no player
    Bullets.spawn(bossX, bossY, speed, 'enemy', damage)
    return
  end
  
  -- Calculate angle to player
  local dx = px - bossX
  local dy = py - bossY
  local distance = math.sqrt(dx*dx + dy*dy)
  
  if distance > 0 then
    local vx = (dx / distance) * speed
    local vy = (dy / distance) * speed
    Bullets.spawn(bossX, bossY, vy, 'enemy', damage, vx)
  end
end

function BossBase.shotgunBurst(bossX, bossY, spreadAngle, pelletCount, speed, damage)
  local Player = require("src.game.player")
  local px, py = Player.x, Player.y
  
  -- Check if player position is available
  if not px or not py then
    -- Default to shooting downward when no player
    local baseAngle = math.pi/2 -- Downward
    for i = 1, pelletCount do
      local angleOffset = (i - (pelletCount + 1) / 2) * spreadAngle / (pelletCount - 1)
      local angle = baseAngle + angleOffset
      
      local vx = math.cos(angle) * speed
      local vy = math.sin(angle) * speed
      Bullets.spawn(bossX, bossY, vy, 'enemy', damage, vx)
    end
    return
  end
  
  -- Calculate base angle to player
  local dx = px - bossX
  local dy = py - bossY
  local baseAngle = math.atan2(dy, dx)
  
  for i = 1, pelletCount do
    local angleOffset = (i - (pelletCount + 1) / 2) * spreadAngle / (pelletCount - 1)
    local angle = baseAngle + angleOffset
    
    local vx = math.cos(angle) * speed
    local vy = math.sin(angle) * speed
    Bullets.spawn(bossX, bossY, vy, 'enemy', damage, vx)
  end
end

function BossBase.starPattern(bossX, bossY, bulletCount, speed, damage)
  for i = 1, bulletCount do
    local angle = (i - 1) * (2 * math.pi / bulletCount)
    local vx = math.cos(angle) * speed
    local vy = math.sin(angle) * speed
    Bullets.spawn(bossX, bossY, vy, 'enemy', damage, vx)
  end
end

function BossBase.spiralPattern(bossX, bossY, bulletCount, speed, damage, rotationOffset)
  local rotation = rotationOffset or 0
  for i = 1, bulletCount do
    local angle = (i - 1) * (2 * math.pi / bulletCount) + rotation
    local vx = math.cos(angle) * speed
    local vy = math.sin(angle) * speed
    Bullets.spawn(bossX, bossY, vy, 'enemy', damage, vx)
  end
end

return BossBase