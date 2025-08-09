local Player = {}
local audio = require("src.audio.audio")

local VIRTUAL_WIDTH, VIRTUAL_HEIGHT = 1280, 720

local DEFAULTS = {
  speed = 360,
  fireRate = 4.0,
  width = 40,
  height = 18,
  margin = 24,
}

function Player.init(virtualW, virtualH)
  VIRTUAL_WIDTH, VIRTUAL_HEIGHT = virtualW or 1280, virtualH or 720
  local y = VIRTUAL_HEIGHT - 64
  Player.x = VIRTUAL_WIDTH / 2
  Player.y = y
  Player.speed = DEFAULTS.speed
  Player.fireRate = DEFAULTS.fireRate
  Player.cooldown = 0
  Player.width = DEFAULTS.width
  Player.height = DEFAULTS.height
  Player.lives = 3
  Player.color = {0.153, 0.953, 1.0, 1.0} -- cyan
  Player.invincibleTimer = 0
  Player.deadTimer = 0
end

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
      Player.invincibleTimer = 2.2
    else
      return -- still dead; skip input/fire
    end
  end

  -- Move
  local move = input.moveAxis or 0
  Player.x = Player.x + move * Player.speed * dt
  local minX = DEFAULTS.margin + Player.width / 2
  local maxX = VIRTUAL_WIDTH - DEFAULTS.margin - Player.width / 2
  if Player.x < minX then Player.x = minX end
  if Player.x > maxX then Player.x = maxX end

  -- Fire (allow holding fire)
  Player.cooldown = math.max(0, Player.cooldown - dt)
  if (input.fireHeld or input.firePressed) and Player.cooldown <= 0 then
    spawnBullet(Player.x, Player.y - Player.height / 2 - 4, -640, 'player', 1)
    Player.cooldown = 1 / Player.fireRate
    if audio and audio.play then audio.play('player_shoot') end
  end
end

function Player.draw()
  if Player.deadTimer > 0 then return end
  local color = Player.color
  local a = color[4] or 1
  if Player.invincibleTimer > 0 then
    -- flashing
    local blink = math.floor(Player.invincibleTimer * 10) % 2
    if blink == 1 then return end
  end
  love.graphics.setColor(color[1], color[2], color[3], a)
  -- Simple ship: triangle
  local halfW = Player.width / 2
  local h = Player.height
  love.graphics.polygon("fill",
    Player.x, Player.y - h/2,
    Player.x - halfW, Player.y + h/2,
    Player.x + halfW, Player.y + h/2
  )
end

function Player.getAABB()
  return Player.x - Player.width/2, Player.y - Player.height/2, Player.width, Player.height
end

function Player.startRespawn()
  -- Trigger death state; actual life decrement handled by game
  Player.deadTimer = 0.8
  Player.cooldown = 0
end

function Player.isVulnerable()
  return Player.deadTimer <= 0 and Player.invincibleTimer <= 0
end

return Player
