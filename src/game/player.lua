local Player = {}
local audio = require("src.audio.audio")
local Cosmetics = require("src.systems.cosmetics")
local Constants = require("src.config.constants")
local Economy = require("src.systems.economy")
local Input = require("src.core.input")

local VIRTUAL_WIDTH, VIRTUAL_HEIGHT = Constants.VIRTUAL_WIDTH, Constants.VIRTUAL_HEIGHT
local DEFAULTS = Constants.PLAYER

--- Initialize player with virtual screen dimensions
--- @param virtualW number Virtual screen width
--- @param virtualH number Virtual screen height
function Player.init(virtualW, virtualH)
  VIRTUAL_WIDTH, VIRTUAL_HEIGHT = virtualW or Constants.VIRTUAL_WIDTH, virtualH or Constants.VIRTUAL_HEIGHT
  local y = VIRTUAL_HEIGHT - Constants.PLAYER.spawnY
  Player.x = VIRTUAL_WIDTH / 2
  Player.y = y
  Player.speed = DEFAULTS.speed
  Player.fireRate = DEFAULTS.fireRate
  Player.cooldown = 0
  Player.width = DEFAULTS.width
  Player.height = DEFAULTS.height
  Player.lives = 3
  -- initial color comes from cosmetics selection
  Player.color = Cosmetics.getColor()
  Player.invincibleTimer = 0
  Player.deadTimer = 0
end

--- Update player state based on input and time
--- @param dt number Delta time in seconds
--- @param input table Input state with moveAxis, fireHeld, firePressed
--- @param spawnBullet function Function to spawn bullets with signature (x, y, dy, from, damage)
function Player.update(dt, input, spawnBullet)
  -- Timers
  if Player.invincibleTimer > 0 then
    Player.invincibleTimer = math.max(0, Player.invincibleTimer - dt)
  end
  if Player.deadTimer > 0 then
    Player.deadTimer = Player.deadTimer - dt
    if Player.deadTimer <= 0 then
      -- respawn in middle with invincibility
      Player.x = VIRTUAL_WIDTH / 2
      Player.invincibleTimer = Constants.PLAYER.invincibilityTime
    else
      return -- still dead; skip input/fire
    end
  end

  -- Move with economy speed upgrade
  -- Economy already required
  local move = input.moveAxis or 0
  local speedMultiplier = Economy.getSpeedMultiplier()
  Player.x = Player.x + move * Player.speed * speedMultiplier * dt
  local minX = DEFAULTS.margin + Player.width / 2
  local maxX = VIRTUAL_WIDTH - DEFAULTS.margin - Player.width / 2
  if Player.x < minX then Player.x = minX end
  if Player.x > maxX then Player.x = maxX end

  -- Fire (allow holding fire) with economy upgrades
  -- Economy already required
  local fireRateMultiplier = Economy.getFireRateMultiplier()
  local multiShot = Economy.getMultiShotCount()
  local piercing = false -- No piercing upgrade in economy system
  
  Player.cooldown = math.max(0, Player.cooldown - dt)
  local shouldFire = (input.fireHeld or input.firePressed) and Player.cooldown <= 0
  
  -- Handle swipe shooting
  -- Input already required at top level
  local swipeDir = Input.getSwipeDirection()
  
  if (swipeDir or shouldFire) and Player.cooldown <= 0 then
    local bulletSpeed = Constants.PLAYER.bulletSpeed
    local baseX = Player.x
    local baseY = Player.y - Player.height / 2 - 4
    
    if swipeDir then
      -- Swipe shooting - single diagonal shot
      local dx = 0
      local dy = -bulletSpeed -- Default upward
      
      if swipeDir == "left" then
        dx = -bulletSpeed * 0.5 -- Diagonal left
        dy = -bulletSpeed * 0.8
      elseif swipeDir == "right" then
        dx = bulletSpeed * 0.5 -- Diagonal right
        dy = -bulletSpeed * 0.8
      end
      
      -- Normalize diagonal shots
      if dx ~= 0 then
        local mag = math.sqrt(dx*dx + dy*dy)
        dx = (dx / mag) * bulletSpeed
        dy = (dy / mag) * bulletSpeed
      end
      
      spawnBullet(baseX, baseY, dy, 'player', 1, dx)
    else
      -- Normal shooting - potentially multi-shot
      if multiShot > 1 then
        -- Multi-shot spread
        local spread = 15 -- degrees
        for i = 1, multiShot do
          local angle = 0
          if multiShot == 3 then
            angle = (i - 2) * spread -- -15, 0, 15 degrees
          elseif multiShot == 2 then
            angle = (i == 1) and -spread/2 or spread/2
          end
          
          local rad = math.rad(angle)
          local dx = math.sin(rad) * bulletSpeed
          local dy = -math.cos(rad) * bulletSpeed
          local offsetX = (i - (multiShot + 1) / 2) * 12
          
          spawnBullet(baseX + offsetX, baseY, dy, 'player', 1, dx)
        end
      else
        -- Single shot
        spawnBullet(baseX, baseY, -bulletSpeed, 'player', 1)
      end
    end
    
    Player.cooldown = 1 / (Player.fireRate * fireRateMultiplier)
    if audio and audio.play then audio.play('player_shoot') end
  end
end

--- Draw the player ship
function Player.draw()
  if Player.deadTimer > 0 then return end
  -- refresh color from cosmetics selection in case it changed
  Player.color = Cosmetics.getColor()
  local color = Player.color
  local a = color[4] or 1
  if Player.invincibleTimer > 0 then
    -- flashing
    local blink = math.floor(Player.invincibleTimer * 10) % 2
    if blink == 1 then return end
  end
  love.graphics.setColor(color[1], color[2], color[3], a)
  -- Draw ship using cosmetics system
  Cosmetics.drawShip(Player.x, Player.y, Player.width, Player.height)
end

--- Get player's axis-aligned bounding box
--- @return number x Left coordinate
--- @return number y Top coordinate  
--- @return number width Width of bounding box
--- @return number height Height of bounding box
function Player.getAABB()
  return Player.x - Player.width/2, Player.y - Player.height/2, Player.width, Player.height
end

--- Start the respawn sequence after death
function Player.startRespawn()
  -- Trigger death state; actual life decrement handled by game
  Player.deadTimer = Constants.PLAYER.respawnTime
  Player.cooldown = 0
end

--- Check if player is vulnerable to damage
--- @return boolean True if player can take damage
function Player.isVulnerable()
  return Player.deadTimer <= 0 and Player.invincibleTimer <= 0
end

return Player
