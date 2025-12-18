local Aliens = {}

local VIRTUAL_WIDTH, VIRTUAL_HEIGHT = 1280, 720
local Constants = require("src.config.constants")
local Bullets = require("src.game.bullets")
local Events = require("src.game.events")
local Waves = require("src.game.waves")

local function flattenPoints(points)
  local flat = {}
  for _, p in ipairs(points) do
    table.insert(flat, p[1])
    table.insert(flat, p[2])
  end
  return flat
end

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

-- --- Alien rendering helpers -------------------------------------------------
local function clampColorComponent(value)
  if value < 0 then return 0 end
  if value > 1 then return 1 end
  return value
end

local function shadeColor(color, delta)
  return clampColorComponent(color[1] + delta),
         clampColorComponent(color[2] + delta),
         clampColorComponent(color[3] + delta)
end

-- Helper for Neon Polygon Rendering
local function drawNeonPolygon(vertices, cx, cy, sx, sy, color, alpha)
  love.graphics.push()
  love.graphics.translate(cx, cy)
  love.graphics.scale(sx, sy)
  
  -- Glass Fill
  love.graphics.setColor(color[1], color[2], color[3], alpha * 0.15)
  love.graphics.polygon("fill", vertices)
  
  -- Glow (just drawing line with width for efficiency vs multiple passes)
  love.graphics.setColor(color[1], color[2], color[3], alpha * 0.4)
  love.graphics.setLineWidth(3)
  love.graphics.polygon("line", vertices)
  
  -- Core Line
  love.graphics.setColor(color[1], color[2], color[3], alpha)
  love.graphics.setLineWidth(1.5)
  love.graphics.polygon("line", vertices)
  
  -- Bright Vertex Highlights (Pointillism effect common in neon)
  love.graphics.setColor(1, 1, 1, alpha * 0.8)
  love.graphics.setPointSize(3)
  -- love.graphics.points(vertices) -- Points drawing requires flattened list processing, skipping for now to safe perf
  
  love.graphics.pop()
  love.graphics.setLineWidth(1)
end

local BASIC_HULL = flattenPoints({
  {0.0, -1.0}, {0.6, -0.45}, {0.85, -0.05}, {0.6, 0.45},
  {0.25, 1.0}, {-0.25, 1.0}, {-0.6, 0.45}, {-0.85, -0.05}, {-0.6, -0.45}
})

local BASIC_PLATE = flattenPoints({
  {0.0, -0.7}, {0.45, -0.2}, {0.4, 0.35}, {0.18, 0.9},
  {-0.18, 0.9}, {-0.4, 0.35}, {-0.45, -0.2}
})

local TANK_BODY = flattenPoints({
  {0.0, -0.9}, {0.75, -0.45}, {0.95, 0.1}, {0.65, 1.0},
  {-0.65, 1.0}, {-0.95, 0.1}, {-0.75, -0.45}
})

local TANK_PLATE = flattenPoints({
  {0.0, -0.5}, {0.4, -0.15}, {0.38, 0.55}, {0.15, 0.85},
  {-0.15, 0.85}, {-0.38, 0.55}, {-0.4, -0.15}
})

local TANK_TURRET = flattenPoints({
  {0.0, -0.95}, {0.18, -0.65}, {0.18, -0.35}, {-0.18, -0.35}, {-0.18, -0.65}
})

local SPEEDY_FUSELAGE = flattenPoints({
  {0.0, -1.0}, {0.28, -0.6}, {0.45, -0.2}, {0.32, 0.3},
  {0.12, 1.0}, {-0.12, 1.0}, {-0.32, 0.3}, {-0.45, -0.2}, {-0.28, -0.6}
})

local SPEEDY_WING = flattenPoints({
  {0.0, -0.2}, {0.75, 0.05}, {0.6, 0.35}, {0.2, 0.25}
})
-- Mirror speedy wing manually for flat array or just draw twice with scale x -1
-- Let's just draw twice with logic

local SNIPER_CORE = flattenPoints({
  {0.0, -0.9}, {0.55, -0.4}, {0.6, 0.2}, {0.3, 0.95},
  {-0.3, 0.95}, {-0.6, 0.2}, {-0.55, -0.4}
})

local SNIPER_SCOPE = flattenPoints({
  {0.0, -0.75}, {0.22, -0.35}, {0.18, 0.32}, {-0.18, 0.32}, {-0.22, -0.35}
})

local GHOST_HULL = flattenPoints({
  {0.0, -1.0}, {0.58, -0.6}, {0.8, -0.05}, {0.65, 0.45},
  {0.35, 1.0}, {0.0, 0.75}, {-0.35, 1.0}, {-0.65, 0.45}, {-0.8, -0.05}, {-0.58, -0.6}
})

local function drawAlienBasic(alien, x, y, w, h, color, alpha)
  local cx, cy = x + w / 2, y + h / 2
  local halfW, halfH = w / 2, h / 2

  -- Main Hull
  drawNeonPolygon(BASIC_HULL, cx, cy, halfW, halfH, color, alpha)
  
  -- Eyes (Glowing)
  love.graphics.setColor(1, 1, 1, alpha)
  local eyeSize = halfH * 0.15
  love.graphics.circle("fill", cx - halfW * 0.3, cy - halfH * 0.1, eyeSize)
  love.graphics.circle("fill", cx + halfW * 0.3, cy - halfH * 0.1, eyeSize)
  
  -- Neon Glow for Eyes
  love.graphics.setColor(color[1], color[2], color[3], alpha * 0.5)
  love.graphics.circle("fill", cx - halfW * 0.3, cy - halfH * 0.1, eyeSize * 2)
  love.graphics.circle("fill", cx + halfW * 0.3, cy - halfH * 0.1, eyeSize * 2)
end

local function drawAlienTank(alien, x, y, w, h, color, alpha)
  local cx, cy = x + w / 2, y + h / 2
  local halfW, halfH = w / 2, h / 2

  -- Heavy Body
  drawNeonPolygon(TANK_BODY, cx, cy, halfW, halfH, color, alpha)
  
  -- Turret
  local turretHeight = halfH * 0.6
  love.graphics.setColor(color[1], color[2], color[3], alpha)
  love.graphics.rectangle("fill", cx - halfW * 0.1, y - halfH * 0.3, halfW * 0.2, turretHeight)
  love.graphics.setColor(1, 1, 1, alpha * 0.8) -- Bright tip
  love.graphics.rectangle("fill", cx - halfW * 0.05, y - halfH * 0.4, halfW * 0.1, halfH * 0.2)
  
  -- Heavy Plating (Inner rect)
  love.graphics.setColor(color[1], color[2], color[3], alpha * 0.3)
  love.graphics.rectangle("line", cx - halfW * 0.6, cy - halfH * 0.2, halfW * 1.2, halfH * 0.6, 4, 4)
end

local function drawAlienSpeedy(alien, x, y, w, h, color, alpha)
  local cx, cy = x + w / 2, y + h / 2
  local halfW, halfH = w / 2, h / 2

  -- Fuselage
  drawNeonPolygon(SPEEDY_FUSELAGE, cx, cy, halfW * 0.8, halfH, color, alpha)
  
  -- Wings (Lines)
  love.graphics.setColor(color[1], color[2], color[3], alpha)
  love.graphics.setLineWidth(2)
  -- Left Wing
  love.graphics.line(cx, cy, cx - halfW, cy + halfH * 0.5)
  love.graphics.line(cx - halfW, cy + halfH * 0.5, cx - halfW * 0.5, cy + halfH * 0.8)
  -- Right Wing
  love.graphics.line(cx, cy, cx + halfW, cy + halfH * 0.5)
  love.graphics.line(cx + halfW, cy + halfH * 0.5, cx + halfW * 0.5, cy + halfH * 0.8)
  love.graphics.setLineWidth(1)
  
  -- Engine glow
  local timer = love.timer.getTime() * 20
  local flicker = math.sin(timer) * 0.2 + 0.8
  love.graphics.setColor(1, 0.5, 0, alpha * flicker)
  love.graphics.circle("fill", cx, cy + halfH * 0.8, halfW * 0.2)
end

local function drawAlienSniper(alien, x, y, w, h, color, alpha)
  local cx, cy = x + w / 2, y + h / 2
  local halfW, halfH = w / 2, h / 2

  drawNeonPolygon(SNIPER_CORE, cx, cy, halfW, halfH, color, alpha)
  
  -- Scope Lens
  love.graphics.setColor(1, 1, 1, alpha * 0.9)
  love.graphics.circle("line", cx, cy - halfH * 0.2, halfH * 0.25)
  love.graphics.setColor(1, 0, 0, alpha) -- Red dot
  love.graphics.circle("fill", cx, cy - halfH * 0.2, 2)
  
  -- Crosshairs
  love.graphics.setColor(color[1], color[2], color[3], alpha * 0.6)
  love.graphics.line(cx, cy - halfH * 0.5, cx, cy + halfH * 0.1)
  love.graphics.line(cx - halfW * 0.3, cy - halfH * 0.2, cx + halfW * 0.3, cy - halfH * 0.2)
end

local function drawAlienGhost(alien, x, y, w, h, color, alpha)
  local cx, cy = x + w / 2, y + h / 2
  local halfW, halfH = w / 2, h / 2

  -- Pulsing alpha for ghost effect
  local pulse = math.abs(math.sin(love.timer.getTime() * 3)) * 0.3 + 0.3
  local ghostAlpha = alpha * pulse
  
  drawNeonPolygon(GHOST_HULL, cx, cy, halfW, halfH, color, ghostAlpha)
  
  -- Spooky eyes
  if not alien.isPhased then
      love.graphics.setColor(1, 1, 1, alpha)
      love.graphics.circle("fill", cx - halfW * 0.25, cy - halfH * 0.1, 2)
      love.graphics.circle("fill", cx + halfW * 0.25, cy - halfH * 0.1, 2)
  end
end

local alienDrawers = {
  basic = drawAlienBasic,
  tank = drawAlienTank,
  speedy = drawAlienSpeedy,
  sniper = drawAlienSniper,
  ghost = drawAlienGhost
}

local function fireAlienPattern(alien, worldX, worldY, playerX, playerY)
  local variant = alien and alien.variant or "basic"
  local baseSpeed = 320
  if variant == "tank" then
    local pelletSpeed = baseSpeed * 0.85
    local spreads = { -120, 0, 120 }
    for _, dx in ipairs(spreads) do
      Bullets.spawn(worldX, worldY, pelletSpeed, 'enemy', 1, dx)
    end
    return 0.15
  elseif variant == "speedy" then
    local dx = ((math.random() < 0.5) and -1 or 1) * 140
    Bullets.spawn(worldX, worldY, baseSpeed * 1.05, 'enemy', 1, dx)
    return 0
  elseif variant == "sniper" then
    local targetX = playerX or worldX
    local targetY = playerY or (worldY + 240)
    local dirX = targetX - worldX
    local dirY = targetY - worldY
    local len = math.sqrt(dirX * dirX + dirY * dirY)
    if len < 1e-4 then
      dirX, dirY = 0, 1
    else
      dirX, dirY = dirX / len, dirY / len
    end
    local speed = baseSpeed * 1.2
    if dirY < 0.1 then dirY = 0.1 end
    Bullets.spawn(worldX, worldY, speed * dirY, 'enemy', 1, speed * dirX)
    return 0.1
  elseif variant == "ghost" then
    local drift = math.sin((alien.phaseTimer or 0) * 2) * 80
    Bullets.spawn(worldX, worldY, baseSpeed * 0.7, 'enemy', 1, drift)
    return 0
  else
    Bullets.spawn(worldX, worldY, baseSpeed, 'enemy', 1)
    return 0
  end
end

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
  -- Waves already required
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
  -- Events already required
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
        local alpha = alien.isPhased and 0.45 or 1.0
        local drawer = alienDrawers[alien.variant] or drawAlienBasic
        drawer(alien, x, y, w, h, color, alpha)
        
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

        love.graphics.setColor(1, 1, 1, 1)
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
        local offsetX = a.xOffset or 0
        table.insert(alive, {alien = a, x = x + offsetX + w/2, y = y + h})
      end
    end
  end
  if #alive == 0 then return nil end
  return alive[math.random(1, #alive)]
end

function Aliens.fireVariantShot(alien, worldX, worldY, playerX, playerY)
  return fireAlienPattern(alien, worldX, worldY, playerX, playerY)
end

function Aliens.checkBulletCollision(bullet)
  if bullet.from ~= 'player' then return false end
  
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
