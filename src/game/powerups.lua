local Powerups = {}
local Constants = require("src.config.constants")
local Particles = require("src.fx.particles")
local audio = require("src.audio.audio")

local VIRTUAL_WIDTH, VIRTUAL_HEIGHT = Constants.VIRTUAL_WIDTH, Constants.VIRTUAL_HEIGHT
local pool = {}
local activePowerups = {}

-- Powerup state
local state = {
  nextSpawnTimer = 0,
  spawnInterval = 15.0, -- Base spawn interval
  chancePerAlien = 0.05, -- Reduced from 15% to 5%
}

local function newPowerup()
  return {
    x = 0,
    y = 0,
    type = nil,
    active = false,
    radius = Constants.POWERUP.radius,
    rotation = 0,
    pulsePhase = math.random() * math.pi * 2
  }
end

function Powerups.init(virtualW, virtualH)
  VIRTUAL_WIDTH, VIRTUAL_HEIGHT = virtualW or Constants.VIRTUAL_WIDTH, virtualH or Constants.VIRTUAL_HEIGHT
  pool = {}
  activePowerups = {}
  state.nextSpawnTimer = state.spawnInterval
  
  for i = 1, Constants.POWERUP.poolSize do
    pool[i] = newPowerup()
  end
end

local function getFree()
  for i = 1, #pool do
    if not pool[i].active then return pool[i] end
  end
  -- Expand pool if needed
  local p = newPowerup()
  table.insert(pool, p)
  return p
end

local function getRandomType()
  local types = {}
  for typeKey, _ in pairs(Constants.POWERUP.types) do
    table.insert(types, typeKey)
  end
  return types[math.random(#types)]
end

--- Spawn a powerup at position
--- @param x number X position
--- @param y number Y position
--- @param typeKey string|nil Specific powerup type (nil for random)
function Powerups.spawn(x, y, typeKey)
  local p = getFree()
  p.x = x
  p.y = y
  p.type = typeKey or getRandomType()
  p.active = true
  p.rotation = 0
  p.pulsePhase = math.random() * math.pi * 2
  
  -- Spawn effect
  local powerupConfig = Constants.POWERUP.types[p.type]
  Particles.burst(x, y, powerupConfig.color, 8, 180)
  if audio and audio.play then audio.play('powerup_spawn') end
end

--- Try to spawn powerup based on alien death
--- @param x number Alien X position
--- @param y number Alien Y position
function Powerups.trySpawnFromAlien(x, y)
  if math.random() < state.chancePerAlien then
    Powerups.spawn(x, y)
  end
end

function Powerups.update(dt)
  -- Update active powerups
  for i = 1, #pool do
    local p = pool[i]
    if p.active then
      -- Fall down
      p.y = p.y + Constants.POWERUP.fallSpeed * dt
      
      -- Rotate and pulse
      p.rotation = p.rotation + dt * 2
      p.pulsePhase = p.pulsePhase + dt * 3
      
      -- Remove if off screen
      if p.y > VIRTUAL_HEIGHT + Constants.POWERUP.offscreenMargin then
        p.active = false
      end
    end
  end
  
  -- Update active powerup effects on player
  for i = #activePowerups, 1, -1 do
    local active = activePowerups[i]
    active.duration = active.duration - dt
    
    if active.duration <= 0 then
      Powerups.removeEffect(active.type)
      table.remove(activePowerups, i)
    end
  end
end

function Powerups.draw()
  for i = 1, #pool do
    local p = pool[i]
    if p.active then
      local powerupConfig = Constants.POWERUP.types[p.type]
      local color = powerupConfig.color
      
      -- Pulsing effect
      local pulse = 1.0 + math.sin(p.pulsePhase) * 0.2
      local radius = p.radius * pulse
      
      -- Glow effect
      for j = 1, 3 do
        local glowRadius = radius + j * 4
        love.graphics.setColor(color[1], color[2], color[3], 0.1 / j)
        love.graphics.circle("line", p.x, p.y, glowRadius)
      end
      
      -- Main powerup
      love.graphics.setColor(color[1], color[2], color[3], 0.9)
      love.graphics.circle("fill", p.x, p.y, radius)
      
      -- Inner design (rotating)
      love.graphics.push()
      love.graphics.translate(p.x, p.y)
      love.graphics.rotate(p.rotation)
      love.graphics.setColor(1, 1, 1, 0.8)
      love.graphics.setLineWidth(2)
      
      -- Draw powerup symbol based on type
      if p.type == "rapid_fire" then
        -- Double arrows
        love.graphics.line(-6, 0, 0, -4, 6, 0)
        love.graphics.line(-6, 4, 0, 0, 6, 4)
      elseif p.type == "triple_shot" then
        -- Three dots
        love.graphics.circle("fill", -6, 0, 2)
        love.graphics.circle("fill", 0, 0, 2)
        love.graphics.circle("fill", 6, 0, 2)
      elseif p.type == "shield" then
        -- Shield shape
        love.graphics.polygon("line", -8, 4, 0, -8, 8, 4)
      elseif p.type == "speed_boost" then
        -- Lightning bolt
        love.graphics.line(-4, -6, 0, 0, -2, 0, 4, 6)
      elseif p.type == "piercing" then
        -- Arrow with lines
        love.graphics.line(0, -8, 0, 8)
        love.graphics.line(-4, -4, 0, -8, 4, -4)
      end
      
      love.graphics.setLineWidth(1)
      love.graphics.pop()
    end
  end
end

--- Check collision with player
--- @param playerX number Player X position
--- @param playerY number Player Y position
--- @param playerRadius number Player collision radius
--- @return string|nil Powerup type if collected
function Powerups.checkPlayerCollision(playerX, playerY, playerRadius)
  for i = 1, #pool do
    local p = pool[i]
    if p.active then
      local dx = p.x - playerX
      local dy = p.y - playerY
      local distance = math.sqrt(dx * dx + dy * dy)
      
      if distance < p.radius + playerRadius then
        local collectedType = p.type
        p.active = false
        
        -- Apply effect
        Powerups.applyEffect(collectedType)
        
        -- Collection effect
        local powerupConfig = Constants.POWERUP.types[collectedType]
        Particles.burst(p.x, p.y, powerupConfig.color, 16, 300)
        if audio and audio.play then audio.play('powerup_collect') end
        
        return collectedType
      end
    end
  end
  return nil
end

--- Apply powerup effect to player
--- @param typeKey string Powerup type
function Powerups.applyEffect(typeKey)
  local powerupConfig = Constants.POWERUP.types[typeKey]
  
  -- Check if player already has this effect
  for _, active in ipairs(activePowerups) do
    if active.type == typeKey then
      -- Reset duration
      active.duration = powerupConfig.duration
      return
    end
  end
  
  -- Check if player already has max active powerups
  if #activePowerups >= Constants.POWERUP.maxActive then
    -- Remove oldest effect to make room
    table.remove(activePowerups, 1)
  end
  
  -- Add new effect
  table.insert(activePowerups, {
    type = typeKey,
    duration = powerupConfig.duration,
    effect = powerupConfig.effect
  })
end

--- Remove powerup effect from player
--- @param typeKey string Powerup type
function Powerups.removeEffect(typeKey)
  -- Effects are removed when duration expires in update()
  -- This function can be used for immediate removal if needed
end

--- Get current active powerup effects
--- @return table List of active effects
function Powerups.getActiveEffects()
  local effects = {}
  for _, active in ipairs(activePowerups) do
    local powerupConfig = Constants.POWERUP.types[active.type]
    table.insert(effects, {
      type = active.type,
      name = powerupConfig.name,
      duration = active.duration,
      maxDuration = powerupConfig.duration,
      color = powerupConfig.color,
      effect = active.effect
    })
  end
  return effects
end

--- Check if player has specific effect
--- @param typeKey string Powerup type
--- @return boolean True if effect is active
function Powerups.hasEffect(typeKey)
  for _, active in ipairs(activePowerups) do
    if active.type == typeKey then
      return true
    end
  end
  return false
end

--- Get effect multiplier for player stats
--- @param statType string Stat type (fireRate, speed, etc.)
--- @return number Multiplier value
function Powerups.getEffectMultiplier(statType)
  local multiplier = 1.0
  for _, active in ipairs(activePowerups) do
    if active.effect[statType .. "Multiplier"] then
      multiplier = multiplier * active.effect[statType .. "Multiplier"]
    end
  end
  return multiplier
end

--- Check if player should fire multiple shots
--- @return number Number of shots (1 if no multi-shot effect)
function Powerups.getMultiShot()
  for _, active in ipairs(activePowerups) do
    if active.effect.multiShot then
      return active.effect.multiShot
    end
  end
  return 1
end

--- Check if player has piercing shots
--- @return boolean True if piercing is active
function Powerups.hasPiercing()
  return Powerups.hasEffect("piercing")
end

--- Check if player is invincible
--- @return boolean True if invincible is active
function Powerups.isInvincible()
  return Powerups.hasEffect("shield")
end

--- Reset all powerups (call on new game/wave)
function Powerups.reset()
  for i = 1, #pool do
    pool[i].active = false
  end
  activePowerups = {}
  state.nextSpawnTimer = state.spawnInterval
end

return Powerups