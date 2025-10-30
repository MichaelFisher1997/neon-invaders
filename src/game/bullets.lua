local Bullets = {}
local Constants = require("src.config.constants")

local VIRTUAL_WIDTH, VIRTUAL_HEIGHT = Constants.VIRTUAL_WIDTH, Constants.VIRTUAL_HEIGHT
local pool = {}

local function newBullet()
  return { x = 0, y = 0, dy = 0, dx = 0, from = 'player', active = false, radius = Constants.BULLET.radius, damage = 1, piercing = 0, enemiesPierced = {} }
end

function Bullets.init(virtualW, virtualH)
  VIRTUAL_WIDTH, VIRTUAL_HEIGHT = virtualW or Constants.VIRTUAL_WIDTH, virtualH or Constants.VIRTUAL_HEIGHT
  pool = {}
  for i = 1, Constants.BULLET.poolSize do pool[i] = newBullet() end
end

local function getFree()
  for i = 1, #pool do
    if not pool[i].active then return pool[i] end
  end
  -- Expand pool if needed (rare)
  local b = newBullet()
  table.insert(pool, b)
  return b
end

function Bullets.spawn(x, y, dy, from, damage, dx)
  local Economy = require("src.systems.economy")
  local b = getFree()
  
  -- Apply economy damage multiplier for player bullets
  local finalDamage = damage or 1
  local piercingLevel = 0
  if (from == 'player') then
    finalDamage = finalDamage * Economy.getDamageMultiplier()
    piercingLevel = Economy.getPiercingLevel()
  end
  
  b.x, b.y, b.dy, b.dx, b.from, b.active, b.damage = x, y, dy, dx or 0, from or 'player', true, finalDamage
  b.piercing = piercingLevel
  b.enemiesPierced = {}
end

function Bullets.update(dt)
  for i = 1, #pool do
    local b = pool[i]
    if b.active then
      b.x = b.x + (b.dx or 0) * dt
      b.y = b.y + b.dy * dt
      if b.y < -Constants.BULLET.offscreenMargin or b.y > VIRTUAL_HEIGHT + Constants.BULLET.offscreenMargin or
         b.x < -Constants.BULLET.offscreenMargin or b.x > VIRTUAL_WIDTH + Constants.BULLET.offscreenMargin then
        b.active = false
      end
    end
  end
end

function Bullets.draw()
  love.graphics.setColor(1, 1, 1, 1)
  for i = 1, #pool do
    local b = pool[i]
    if b.active then
      love.graphics.circle("fill", b.x, b.y, b.radius)
    end
  end
end

function Bullets.eachActive(callback)
  for i = 1, #pool do
    local b = pool[i]
    if b.active then callback(b) end
  end
end

function Bullets.canPierce(bullet, alienId)
  if bullet.piercing <= 0 then return false end
  if bullet.enemiesPierced[alienId] then return false end
  if #bullet.enemiesPierced >= bullet.piercing then return false end
  return true
end

function Bullets.markPierced(bullet, alienId)
  if bullet.piercing > 0 then
    table.insert(bullet.enemiesPierced, alienId)
  end
end

function Bullets.clear(from)
  for i = 1, #pool do
    local b = pool[i]
    if b.active and (from == nil or b.from == from) then
      b.active = false
    end
  end
end

return Bullets
