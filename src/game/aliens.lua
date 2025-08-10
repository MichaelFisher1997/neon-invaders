local Aliens = {}

local VIRTUAL_WIDTH, VIRTUAL_HEIGHT = 1280, 720

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


local function resetAliens()
  formation.aliens = {}
  for r = 1, formation.rows do
    formation.aliens[r] = {}
    for c = 1, formation.cols do
      formation.aliens[r][c] = { alive = true, x = (c-1)*formation.spacingX, y = (r-1)*formation.spacingY, w = ALIEN_W, h = ALIEN_H, score = 10 }
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
  -- March horizontally; step down on edges
  formation.originX = formation.originX + formation.dir * formation.speed * dt
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
      local a = formation.aliens[r][c]
      if a.alive then
        local x, y, w, h = worldAABB(a)
        love.graphics.setColor(1.0, 0.182, 0.651, 1.0) -- magenta
        love.graphics.rectangle("fill", x, y, w, h, 4, 4)
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
  for r = 1, formation.rows do
    for c = 1, formation.cols do
      local a = formation.aliens[r][c]
      if a.alive then
        local x, y, w, h = worldAABB(a)
        local dx = math.max(x - bullet.x, 0, bullet.x - (x + w))
        local dy = math.max(y - bullet.y, 0, bullet.y - (y + h))
        if dx*dx + dy*dy <= (bullet.radius * bullet.radius) then
          a.alive = false
          return a.score
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

return Aliens
