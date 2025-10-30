local Bullets = require("src.game.bullets")

local Boss = {}

local VIRTUAL_WIDTH, VIRTUAL_HEIGHT = 1280, 720

local data

function Boss.spawnFromConfig(cfg, vw, vh)
  VIRTUAL_WIDTH, VIRTUAL_HEIGHT = vw or 1280, vh or 720
  -- More aggressive boss health scaling: base 20 + 6 HP per wave + bonus every 10 waves
  local baseHP = 20 + 6 * cfg.wave
  local bonusHP = 2 * math.floor(cfg.wave / 10)
  local hpMax = baseHP + bonusHP

  data = {
    x = VIRTUAL_WIDTH / 2,
    y = 140,
    w = 160,
    h = 64,
    dir = 1,
    speed = 120,
    hpMax = hpMax,
    hp = hpMax,
    fireCooldown = 0,
    fireRate = 1.2 + 0.2 * math.floor(cfg.wave / 5),
  }
end

function Boss.exists()
  return data ~= nil
end

function Boss.update(dt)
  if not data then return end
  data.x = data.x + data.dir * data.speed * dt
  if data.x + data.w/2 >= VIRTUAL_WIDTH - 24 then data.dir = -1 end
  if data.x - data.w/2 <= 24 then data.dir = 1 end

  data.fireCooldown = data.fireCooldown - dt
  if data.fireCooldown <= 0 then
    -- multi-shot pattern: 3-way straight shots
    local spacing = 48
    for i=-1,1 do
      Bullets.spawn(data.x + i*spacing, data.y + data.h/2 + 8, 380, 'enemy', 1)
    end
    data.fireCooldown = 1 / data.fireRate
  end
end

function Boss.draw()
  if not data then return end
  -- body
  love.graphics.setColor(0.541, 0.169, 0.886, 1.0) -- purple
  love.graphics.rectangle('fill', data.x - data.w/2, data.y - data.h/2, data.w, data.h, 10, 10)
  -- hp bar
  local barW = 240
  local ratio = data.hp / data.hpMax
  love.graphics.setColor(1,1,1,1)
  love.graphics.rectangle('line', VIRTUAL_WIDTH/2 - barW/2, 32, barW, 10)
  love.graphics.setColor(1.0, 0.182, 0.651, 1.0)
  love.graphics.rectangle('fill', VIRTUAL_WIDTH/2 - barW/2 + 2, 34, (barW-4) * math.max(0, ratio), 6)
end

function Boss.aabb()
  if not data then return nil end
  return data.x - data.w/2, data.y - data.h/2, data.w, data.h
end

function Boss.hit(dmg)
  if not data then return false end
  data.hp = data.hp - (dmg or 1)
  if data.hp <= 0 then
    data = nil
    return true
  end
  return false
end

return Boss
