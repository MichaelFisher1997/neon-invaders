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

local edgeLock = false

local function resetAliens()
  formation.aliens = {}
  for r = 1, formation.rows do
    formation.aliens[r] = {}
    for c = 1, formation.cols do
      formation.aliens[r][c] = { alive = true, x = (c-1)*formation.spacingX, y = (r-1)*formation.spacingY, w = 48, h = 28, score = 10 }
    end
  end
end

function Aliens.init(virtualW, virtualH)
  VIRTUAL_WIDTH, VIRTUAL_HEIGHT = virtualW or 1280, virtualH or 720
  formation.originX = 160
  formation.originY = 120
  formation.dir = 1
  formation.speed = 80
  formation.stepDown = 24
  formation.cols = 8
  formation.rows = 1
  resetAliens()
  edgeLock = false
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
  formation.originX = formation.originX + formation.dir * formation.speed * dt
  local left, right, bottom = computeBounds()
  local rightLimit = VIRTUAL_WIDTH - 24
  local leftLimit = 24
  if formation.dir == 1 and right >= rightLimit and not edgeLock then
    formation.dir = -1
    formation.originY = formation.originY + formation.stepDown
    edgeLock = true
  elseif formation.dir == -1 and left <= leftLimit and not edgeLock then
    formation.dir = 1
    formation.originY = formation.originY + formation.stepDown
    edgeLock = true
  end
  if left > leftLimit and right < rightLimit then
    edgeLock = false
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
  -- Center horizontally to avoid immediate edge hit
  local alienW = 48
  local totalWidth = (formation.cols - 1) * formation.spacingX + alienW
  formation.originX = math.max(24, math.floor((VIRTUAL_WIDTH - totalWidth) / 2 + 0.5))
  -- Safety: ensure formation spawns high enough above the player
  local defaultY = 120
  local minOriginY = 60
  local totalHeight = (formation.rows - 1) * formation.spacingY + 28 -- alien height ~= 28
  local twoRows = 2 * formation.spacingY
  local safeBottomY = (playerY or (VIRTUAL_HEIGHT - 64)) - twoRows
  local safeOriginY = math.min(defaultY, safeBottomY - totalHeight)
  if safeOriginY < minOriginY then safeOriginY = minOriginY end
  formation.originY = math.floor(safeOriginY + 0.5)
  formation.dir = 1
  resetAliens()
  edgeLock = false
end

return Aliens
