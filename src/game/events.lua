local Events = {}
local Constants = require("src.config.constants")
local Particles = require("src.fx.particles")
local Screenshake = require("src.fx.screenshake")
local audio = require("src.audio.audio")

local VIRTUAL_WIDTH, VIRTUAL_HEIGHT = Constants.VIRTUAL_WIDTH, Constants.VIRTUAL_HEIGHT

-- Event system state
local state = {
  activeEvents = {},
  nextEventTimer = 0,
  eventInterval = 30.0, -- Increased from 20.0 to make events more special
  currentWave = 1,
}

-- Event types
local EVENT_TYPES = {
  meteor_shower = {
    name = "Meteor Shower",
    duration = 8.0,
    color = {0.8, 0.4, 0.2, 1.0}, -- Orange
    warning = "METEOR SHOWER INCOMING!",
    warningDuration = 2.0
  },
  
  power_surge = {
    name = "Power Surge",
    duration = 6.0,
    color = {0.2, 1.0, 0.8, 1.0}, -- Cyan
    warning = "POWER SURGE DETECTED!",
    warningDuration = 1.5
  },
  
  alien_reinforcements = {
    name = "Reinforcements",
    duration = 10.0,
    color = {1.0, 0.2, 0.4, 1.0}, -- Red
    warning = "ENEMY REINFORCEMENTS!",
    warningDuration = 2.5
  },
  
  time_warp = {
    name = "Time Warp",
    duration = 5.0,
    color = {0.8, 0.2, 1.0, 1.0}, -- Purple
    warning = "TIME WARP ACTIVATED!",
    warningDuration = 1.0
  }
}

-- Meteor shower system
local meteors = {}

local function createMeteor()
  return {
    x = math.random(50, VIRTUAL_WIDTH - 50),
    y = -30,
    vx = (math.random() - 0.5) * 100,
    vy = math.random(200, 400),
    radius = math.random(8, 20),
    active = false
  }
end

local function initMeteors()
  meteors = {}
  for i = 1, 20 do
    meteors[i] = createMeteor()
  end
end

local function spawnMeteor()
  for i = 1, #meteors do
    if not meteors[i].active then
      meteors[i] = createMeteor()
      meteors[i].active = true
      break
    end
  end
end

local function updateMeteors(dt)
  for i = 1, #meteors do
    local meteor = meteors[i]
    if meteor.active then
      meteor.x = meteor.x + meteor.vx * dt
      meteor.y = meteor.y + meteor.vy * dt
      
      -- Remove if off screen
      if meteor.y > VIRTUAL_HEIGHT + 50 then
        meteor.active = false
      end
    end
  end
end

local function drawMeteors()
  for i = 1, #meteors do
    local meteor = meteors[i]
    if meteor.active then
      -- Draw meteor with trail effect
      for j = 3, 1, -1 do
        local trailY = meteor.y - j * 15
        local alpha = 0.3 / j
        love.graphics.setColor(0.8, 0.4, 0.2, alpha)
        love.graphics.circle("fill", meteor.x, trailY, meteor.radius * (1 - j * 0.2))
      end
      
      love.graphics.setColor(0.8, 0.4, 0.2, 1.0)
      love.graphics.circle("fill", meteor.x, meteor.y, meteor.radius)
    end
  end
end

local function checkMeteorCollisions(playerX, playerY, playerRadius)
  for i = 1, #meteors do
    local meteor = meteors[i]
    if meteor.active then
      local dx = meteor.x - playerX
      local dy = meteor.y - playerY
      local distance = math.sqrt(dx * dx + dy * dy)
      
      if distance < meteor.radius + playerRadius then
        meteor.active = false
        return true -- Hit player
      end
    end
  end
  return false
end

-- Event management
local function getRandomEvent()
  local events = {}
  for eventType, _ in pairs(EVENT_TYPES) do
    table.insert(events, eventType)
  end
  return events[math.random(#events)]
end

local function startEvent(eventType)
  local eventConfig = EVENT_TYPES[eventType]
  local event = {
    type = eventType,
    name = eventConfig.name,
    duration = eventConfig.duration,
    timeRemaining = eventConfig.duration,
    color = eventConfig.color,
    active = true
  }
  
  table.insert(state.activeEvents, event)
  
  -- Show warning banner
  local Banner = require("src.ui.banner")
  Banner.trigger(eventConfig.warning, eventConfig.warningDuration)
  
  -- Initialize event-specific systems
  if eventType == "meteor_shower" then
    initMeteors()
  end
  
  if audio and audio.play then audio.play('event_start') end
end

local function updateEvent(event, dt)
  event.timeRemaining = event.timeRemaining - dt
  
  if event.timeRemaining <= 0 then
    event.active = false
    return true -- Event ended
  end
  
  -- Update event-specific logic
  if event.type == "meteor_shower" then
    updateMeteors(dt)
    -- Spawn meteors periodically
    if math.random() < dt * 2 then -- 2 meteors per second on average
      spawnMeteor()
    end
  elseif event.type == "power_surge" then
    -- Power surge effect: temporary powerup spawn chance (reduced)
    local Powerups = require("src.game.powerups")
    if math.random() < dt * 0.15 then -- Reduced from 0.5 to 0.15 per second
      local x = math.random(100, VIRTUAL_WIDTH - 100)
      local y = math.random(50, 200)
      Powerups.spawn(x, y)
    end
  end
  
  return false
end

function Events.init(virtualW, virtualH)
  VIRTUAL_WIDTH, VIRTUAL_WIDTH = virtualW or Constants.VIRTUAL_WIDTH, virtualH or Constants.VIRTUAL_HEIGHT
  state.activeEvents = {}
  state.nextEventTimer = state.eventInterval
  initMeteors()
end

function Events.update(dt, wave)
  state.currentWave = wave
  
  -- Update event timer
  state.nextEventTimer = state.nextEventTimer - dt
  
  -- Try to start new event
  if state.nextEventTimer <= 0 and #state.activeEvents == 0 then
    local eventType = getRandomEvent()
    startEvent(eventType)
    state.nextEventTimer = state.eventInterval + math.random(-5, 5) -- Random variation
  end
  
  -- Update active events
  for i = #state.activeEvents, 1, -1 do
    local event = state.activeEvents[i]
    local ended = updateEvent(event, dt)
    
    if ended then
      table.remove(state.activeEvents, i)
      if audio and audio.play then audio.play('event_end') end
    end
  end
end

function Events.draw()
  -- Draw event-specific effects
  for _, event in ipairs(state.activeEvents) do
    if event.type == "meteor_shower" then
      drawMeteors()
    elseif event.type == "time_warp" then
      -- Time warp visual effect
      love.graphics.setColor(0.8, 0.2, 1.0, 0.1)
      love.graphics.rectangle("fill", 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
      
      -- Warp lines
      love.graphics.setColor(0.8, 0.2, 1.0, 0.3)
      love.graphics.setLineWidth(2)
      for i = 1, 5 do
        local y = (math.sin(love.timer.getTime() * 2 + i) + 1) * VIRTUAL_HEIGHT / 2
        love.graphics.line(0, y, VIRTUAL_WIDTH, y)
      end
      love.graphics.setLineWidth(1)
    end
  end
end

function Events.checkPlayerCollisions(playerX, playerY, playerRadius)
  -- Check meteor collisions
  for _, event in ipairs(state.activeEvents) do
    if event.type == "meteor_shower" then
      if checkMeteorCollisions(playerX, playerY, playerRadius) then
        return true -- Player hit by meteor
      end
    end
  end
  return false
end

function Events.getActiveEvents()
  local active = {}
  for _, event in ipairs(state.activeEvents) do
    table.insert(active, {
      type = event.type,
      name = event.name,
      timeRemaining = event.timeRemaining,
      duration = event.duration,
      color = event.color
    })
  end
  return active
end

function Events.hasEventType(eventType)
  for _, event in ipairs(state.activeEvents) do
    if event.type == eventType then
      return true
    end
  end
  return false
end

function Events.getTimeWarpFactor()
  -- Time warp slows down enemies
  if Events.hasEventType("time_warp") then
    return 0.5 -- 50% speed
  end
  return 1.0
end

function Events.reset()
  state.activeEvents = {}
  state.nextEventTimer = state.eventInterval
  meteors = {}
end

return Events