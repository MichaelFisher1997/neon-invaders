local Bullets = {}

local VIRTUAL_WIDTH, VIRTUAL_HEIGHT = 1280, 720

local pool = {}

local function newBullet()
  return { x = 0, y = 0, dy = 0, from = 'player', active = false, radius = 4, damage = 1 }
end

function Bullets.init(virtualW, virtualH)
  VIRTUAL_WIDTH, VIRTUAL_HEIGHT = virtualW or 1280, virtualH or 720
  pool = {}
  for i = 1, 128 do pool[i] = newBullet() end
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

function Bullets.spawn(x, y, dy, from, damage)
  local b = getFree()
  b.x, b.y, b.dy, b.from, b.active, b.damage = x, y, dy, from or 'player', true, damage or 1
end

function Bullets.update(dt)
  for i = 1, #pool do
    local b = pool[i]
    if b.active then
      b.y = b.y + b.dy * dt
      if b.y < -16 or b.y > VIRTUAL_HEIGHT + 16 then
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

function Bullets.clear(from)
  for i = 1, #pool do
    local b = pool[i]
    if b.active and (from == nil or b.from == from) then
      b.active = false
    end
  end
end

return Bullets
