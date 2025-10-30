local Aliens = {}

local VIRTUAL_WIDTH, VIRTUAL_HEIGHT = 1280, 720
local Constants = require("src.config.constants")

local formation = {
  originX = 160,
  originY = 120,
  dir = 1,
  speed = 80,
  stepDown = 24,
  cols = 8,
  rows = 1,
  spacingX = 96,
  spacingY = 64,
  aliens = {},
}

local ALIEN_W, ALIEN_H = 36, 22

-- Enemy behavior patterns
local behaviors = {
  march = function(alien, dt)
    -- Standard marching behavior - handled by formation movement
  end,
  
  zigzag = function(alien, dt)
    -- Zigzag movement for individual aliens
    alien.zigzagPhase = (alien.zigzagPhase or 0) + dt * 3
    alien.xOffset = math.sin(alien.zigzagPhase) * 20
  end,
  
  phase = function(alien, dt)
    -- Phasing behavior - chance to avoid damage
    alien.phaseTimer = (alien.phaseTimer or 0) + dt
    alien.isPhased = (math.floor(alien.phaseTimer * 2) % 2) == 1
  end
}

local function resetAliens()
  formation.aliens = {}
  for r = 1, formation.rows do
    formation.aliens[r] = {}
    for c = 1, formation.cols do
      local variantType = "basic"
      -- Reduced variant spawn rates for better balance
      if math.random() < 0.08 then variantType = "tank" -- Reduced from 0.2
      elseif math.random() < 0.06 then variantType = "speedy" -- Reduced from 0.15
      elseif math.random() < 0.04 then variantType = "sniper" -- Reduced from 0.1
      elseif math.random() < 0.02 then variantType = "ghost" -- Reduced from 0.05
      end
      
      local variant = Constants.ALIEN_VARIANTS[variantType]
      local alien = {
        alive = true,
        x = (c-1)*formation.spacingX,
        y = (r-1)*formation.spacingY,
        w = ALIEN_W * variant.size,
        h = ALIEN_H * variant.size,
        variant = variantType,
        health = variant.health,
        maxHealth = variant.health,
        score = variant.score,
        zigzagPhase = math.random() * math.pi * 2,
        phaseTimer = 0,
        xOffset = 0,
        isPhased = false
      }
      formation.aliens[r][c] = alien
    end
  end
end

function Aliens.init(virtualW, virtualH)
  VIRTUAL_WIDTH, VIRTUAL_HEIGHT = virtualW or 1280, virtualH or 720
  local Waves = require('src.game.waves')
  local cfg = Waves.configFor(1)
  formation.dir = 1 -- horizontal marching enabled
  formation.speed = cfg.formationSpeed
  formation.stepDown = cfg.stepDown
  formation.cols = cfg.cols
  formation.rows = cfg.rows
  -- Center and fit within the center viewport using respawn logic
  Aliens.respawnFromConfig(cfg, nil)
end

local function worldAABB(a)
  local x = formation.originX + a.x
  local y = formation.originY + a.y
  return x, y, a.w, a.h
end

local function computeBounds()
  local left, right, bottom = math.huge, -math.huge, -math.huge
  for r = 1, formation.rows do
    for c = 1, formation.cols do
      local a = formation.aliens[r][c]
      if a.alive then
        local x, y, w, h = worldAABB(a)
        if x < left then left = x end
        if x + w > right then right = x + w end
        if y + h > bottom then bottom = y + h end
      end
    end
  end
  if left == math.huge then left, right, bottom = 0, 0, 0 end
  return left, right, bottom
end

function Aliens.update(dt)
  -- Apply time warp effect
  local Events = require("src.game.events")
  local timeFactor = Events.getTimeWarpFactor()
  local adjustedDt = dt * timeFactor
  
  -- Update individual alien behaviors
  for r = 1, formation.rows do
    for c = 1, formation.cols do
      local alien = formation.aliens[r][c]
      if alien.alive then
        local variant = Constants.ALIEN_VARIANTS[alien.variant]
        local behavior = behaviors[variant.behavior]
        if behavior then
          behavior(alien, adjustedDt)
        end
      end
    end
  end
  
  -- March horizontally; step down on edges
  formation.originX = formation.originX + formation.dir * formation.speed * adjustedDt
  local left, right, bottom = computeBounds()
  local rightLimit = VIRTUAL_WIDTH - 24
  local leftLimit = 24
  if formation.dir == 1 and right >= rightLimit then
    local overshoot = right - rightLimit
    formation.originX = formation.originX - overshoot
    formation.dir = -1
    formation.originY = formation.originY + formation.stepDown
  elseif formation.dir == -1 and left <= leftLimit then
    local overshoot = leftLimit - left
    formation.originX = formation.originX + overshoot
    formation.dir = 1
    formation.originY = formation.originY + formation.stepDown
  end
  return bottom
end

function Aliens.draw()
  for r = 1, formation.rows do
    for c = 1, formation.cols do
      local alien = formation.aliens[r][c]
      if alien.alive then
        local variant = Constants.ALIEN_VARIANTS[alien.variant]
        local x, y, w, h = worldAABB(alien)
        
        -- Apply individual offset for behaviors
        x = x + (alien.xOffset or 0)
        
        -- Draw alien with variant color and effects
        local color = variant.color
        if alien.isPhased then
          -- Phased aliens are semi-transparent
          love.graphics.setColor(color[1], color[2], color[3], 0.4)
        else
          love.graphics.setColor(color[1], color[2], color[3], 1.0)
        end
        
        love.graphics.rectangle("fill", x, y, w, h, 4, 4)
        
        -- Draw health bar for multi-health aliens
        if alien.health > 1 and alien.health < alien.maxHealth then
          local barWidth = w * 0.8
          local barHeight = 3
          local barX = x + (w - barWidth) / 2
          local barY = y - 8
          
          -- Background
          love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
          love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
          
          -- Health fill
          local healthPercent = alien.health / alien.maxHealth
          love.graphics.setColor(1.0, 0.2, 0.2, 1.0)
          love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight)
        end
        
        -- Draw variant-specific indicators
        love.graphics.setColor(1, 1, 1, 0.8)
        if alien.variant == "speedy" then
          -- Speed lines
          love.graphics.line(x - 4, y + h/2, x + w + 4, y + h/2)
        elseif alien.variant == "sniper" then
          -- Target indicator
          love.graphics.circle("line", x + w/2, y + h/2, 4)
        elseif alien.variant == "ghost" and alien.isPhased then
          -- Ghost effect
          love.graphics.setColor(color[1], color[2], color[3], 0.2)
          love.graphics.rectangle("fill", x - 2, y - 2, w + 4, h + 4, 4, 4)
        end
      end
    end
  end
end

function Aliens.getRandomAliveWorld()
  local alive = {}
  for r = 1, formation.rows do
    for c = 1, formation.cols do
      local a = formation.aliens[r][c]
      if a.alive then
        local x, y, w, h = worldAABB(a)
        table.insert(alive, {x=x + w/2, y=y + h})
      end
    end
  end
  if #alive == 0 then return nil end
  return alive[math.random(1, #alive)]
end

function Aliens.checkBulletCollision(bullet)
  if bullet.from ~= 'player' then return false end
  local Bullets = require("src.game.bullets")
  
  for r = 1, formation.rows do
    for c = 1, formation.cols do
      local alien = formation.aliens[r][c]
      if alien.alive then
        local variant = Constants.ALIEN_VARIANTS[alien.variant]
        local x, y, w, h = worldAABB(alien)
        
        -- Apply individual offset for behaviors
        x = x + (alien.xOffset or 0)
        
        local dx = math.max(x - bullet.x, 0, bullet.x - (x + w))
        local dy = math.max(y - bullet.y, 0, bullet.y - (y + h))
        
        if dx*dx + dy*dy <= (bullet.radius * bullet.radius) then
          -- Check if this bullet can pierce this alien
          local alienId = tostring(r) .. "," .. tostring(c)
          if bullet.piercing > 0 and not Bullets.canPierce(bullet, alienId) then
            return false -- Bullet already hit this alien or exceeded pierce limit
          end
          
          -- Check for phasing
          if alien.isPhased and variant.behavior == "phase" then
            -- Ghost aliens have chance to phase through bullets
            if math.random() < (variant.phaseChance or 0.3) then
              return false -- Bullet passes through
            end
          end
          
          -- Apply damage
          alien.health = alien.health - (bullet.damage or 1)
          
          -- Mark this alien as pierced by this bullet
          Bullets.markPierced(bullet, alienId)
          
          if alien.health <= 0 then
            alien.alive = false
            return alien.score
          else
            -- Hit but not destroyed
            return 0
          end
        end
      end
    end
  end
  return false
end

function Aliens.allCleared()
  for r = 1, formation.rows do
    for c = 1, formation.cols do
      if formation.aliens[r][c].alive then return false end
    end
  end
  return true
end

function Aliens.getAlienAtWorld(worldX, worldY)
  for r = 1, formation.rows do
    for c = 1, formation.cols do
      local alien = formation.aliens[r][c]
      if alien.alive then
        local x, y, w, h = worldAABB(alien)
        x = x + (alien.xOffset or 0)
        
        if worldX >= x and worldX <= x + w and worldY >= y and worldY <= y + h then
          return alien
        end
      end
    end
  end
  return nil
end

function Aliens.respawnFromConfig(cfg, playerY)
  formation.cols = cfg.cols
  formation.rows = cfg.rows
  formation.speed = cfg.formationSpeed
  formation.stepDown = cfg.stepDown
  -- Fit formation within center width with margins; adjust cols/spacing if needed
  local sideMargin = 24
  local availableW = VIRTUAL_WIDTH - 2 * sideMargin
  local marchSpace = 48 -- ensure travel room on both sides so formation doesn't start on an edge
  local minSpacingX = 56
  -- Reduce columns if they cannot fit even with minimum spacing
  while formation.cols > 1 and ((formation.cols - 1) * minSpacingX + ALIEN_W) > (availableW - 2 * marchSpace) do
    formation.cols = formation.cols - 1
  end
  -- Compute spacingX to fill available width nicely
  if formation.cols > 1 then
    formation.spacingX = math.max(minSpacingX, math.floor(((availableW - 2 * marchSpace) - ALIEN_W) / (formation.cols - 1)))
  else
    formation.spacingX = 0
  end
  local totalWidth = (formation.cols - 1) * formation.spacingX + ALIEN_W
  formation.originX = math.floor((VIRTUAL_WIDTH - totalWidth) / 2 + 0.5)
  if formation.originX + totalWidth > VIRTUAL_WIDTH - sideMargin then
    formation.originX = VIRTUAL_WIDTH - sideMargin - totalWidth
  end
  -- Safety: ensure formation spawns high enough above the player
  local defaultY = 120
  local minOriginY = 60
  -- Fit vertically with safe buffer from player
  local minSpacingY = 48
  formation.spacingY = math.max(minSpacingY, formation.spacingY)
  local totalHeight = (formation.rows - 1) * formation.spacingY + ALIEN_H
  local twoRows = 2 * formation.spacingY
  local safeBottomY = (playerY or (VIRTUAL_HEIGHT - 64)) - twoRows
  -- Place formation so its bottom stays at least two rows above the player; stack new rows upward if needed
  local desiredOriginY = math.min(defaultY, safeBottomY - totalHeight)
  if desiredOriginY < minOriginY then desiredOriginY = minOriginY end
  formation.originY = math.floor(desiredOriginY + 0.5)
  formation.dir = (formation.dir == 0) and 1 or formation.dir -- ensure marching resumes after respawn
  resetAliens()
end

function Aliens.spawnReinforcement(variantType)
  variantType = variantType or "basic"
  
  -- Find a valid spawn position at the top
  local spawnRow = 1
  local spawnCol = math.random(1, formation.cols)
  
  -- Check if position is available, if not try nearby columns
  local attempts = 0
  while attempts < formation.cols do
    if not formation.aliens[spawnRow][spawnCol] or not formation.aliens[spawnRow][spawnCol].alive then
      break
    end
    spawnCol = (spawnCol % formation.cols) + 1
    attempts = attempts + 1
  end
  
  if attempts < formation.cols then
    local variant = Constants.ALIEN_VARIANTS[variantType]
    local alien = {
      alive = true,
      x = (spawnCol-1)*formation.spacingX,
      y = (spawnRow-1)*formation.spacingY,
      w = ALIEN_W * variant.size,
      h = ALIEN_H * variant.size,
      variant = variantType,
      health = variant.health * 1.5, -- Reinforcements are 50% tougher
      maxHealth = variant.health * 1.5,
      score = variant.score * 2, -- Double score for killing reinforcements
      zigzagPhase = math.random() * math.pi * 2,
      phaseTimer = 0,
      xOffset = 0,
      isPhased = false,
      shootTimer = 0,
      behavior = variant.behavior,
      behaviorTimer = 0
    }
    formation.aliens[spawnRow][spawnCol] = alien
  end
end

return Aliens
