local Bullets = {}
local Constants = require("src.config.constants")
local Neon = require("src.ui.neon_ui")

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

local function drawPlayerBullet(b)
  local x, y = b.x, b.y
  local sz = b.radius or 3
  
  -- Trail effect (fading behind)
  love.graphics.setColor(Neon.COLORS.cyan[1], Neon.COLORS.cyan[2], Neon.COLORS.cyan[3], 0.4)
  love.graphics.setLineWidth(2)
  love.graphics.line(x, y + 5, x, y + 15)
  
  -- Outer Glow
  love.graphics.setColor(Neon.COLORS.blue[1], Neon.COLORS.blue[2], Neon.COLORS.blue[3], 0.3)
  love.graphics.circle("fill", x, y, sz * 2.5)
  
  -- Inner Glow
  love.graphics.setColor(Neon.COLORS.cyan[1], Neon.COLORS.cyan[2], Neon.COLORS.cyan[3], 0.8)
  love.graphics.circle("fill", x, y, sz * 1.5)
  
  -- Intense Core
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.circle("fill", x, y, sz)
  
  -- Piercing indicator (sparkles)
  if b.piercing and b.piercing > 0 then
    love.graphics.setColor(Neon.COLORS.gold[1], Neon.COLORS.gold[2], Neon.COLORS.gold[3], 0.8)
    local t = love.timer.getTime() * 10
    local px = x + math.sin(t) * 3
    local py = y + math.cos(t) * 3
    love.graphics.circle("fill", px, py, 1.5)
  end
end

local function drawEnemyBullet(b)
  local x, y = b.x, b.y
  local r = b.radius or 3
  
  -- Pulsating Plasma Effect
  local pulse = math.sin(love.timer.getTime() * 15) * 0.2 + 1.0
  
  -- Deadly Red/Purple Glow
  love.graphics.setColor(Neon.COLORS.red[1], Neon.COLORS.red[2], Neon.COLORS.red[3], 0.25)
  love.graphics.circle("fill", x, y, r * 2.5 * pulse)
  
  -- Main Orb
  love.graphics.setColor(Neon.COLORS.magenta[1], Neon.COLORS.magenta[2], Neon.COLORS.magenta[3], 0.8)
  love.graphics.circle("fill", x, y, r * 1.2)
  
  -- Bright Core
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.circle("fill", x, y, r * 0.6)
  
  -- Jagged Energy Ring (Rotating)
  local angle = love.timer.getTime() * 5
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(angle)
  love.graphics.setColor(Neon.COLORS.red[1], Neon.COLORS.red[2], Neon.COLORS.red[3], 0.8)
  love.graphics.setLineWidth(1.5)
  love.graphics.rectangle("line", -r, -r, r*2, r*2) -- Rotating square looks cool/jagged
  love.graphics.pop()
  
  love.graphics.setLineWidth(1)
end

function Bullets.draw()
  for i = 1, #pool do
    local b = pool[i]
    if b.active then
      if b.from == 'player' then
        drawPlayerBullet(b)
      else
        drawEnemyBullet(b)
      end
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
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

function Bullets.getPool()
  return pool
end

return Bullets
