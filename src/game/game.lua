local Player = require("src.game.player")
local Bullets = require("src.game.bullets")
local Aliens = require("src.game.aliens")
local Particles = require("src.fx.particles")
local Screenshake = require("src.fx.screenshake")
local Waves = require("src.game.waves")
local Banner = require("src.ui.banner")
local Boss = require("src.game.boss")
local Upgrades = require("src.game.upgrades")
local Cosmetics = require("src.systems.cosmetics")
local Economy = require("src.systems.economy")
-- No powerup module in economy system
local Events = require("src.game.events")
local scaling = require("src.systems.scaling")
local Constants = require("src.config.constants")

local Game = {}

local VIRTUAL_WIDTH, VIRTUAL_HEIGHT = 1280, 720

local score = 0
local wave = 1
local isGameOver = false
local enemyFireCooldown = 0
local intermissionPending = false
local pendingNextCfg = nil
local bossSpawned = false
local waveGraceTimer = 0

local function setWave(newWave, announceBonus)
  wave = math.max(newWave, 1)
  local multiplierChanged = Economy.updateCreditMultiplier(wave)
  if announceBonus and multiplierChanged and Economy.getCreditMultiplier() > 1 then
    local bonus = Economy.getCreditMultiplier()
    local milestoneWave = Economy.getCreditMilestoneWave()
    Banner.trigger(string.format("Credit Bonus x%d unlocked! (Wave %d)", bonus, milestoneWave))
  end
end

function Game.init(vw, vh)
  VIRTUAL_WIDTH, VIRTUAL_HEIGHT = vw or 1280, vh or 720
  score = 0
  isGameOver = false
  local _, center, _ = scaling.getPanelsVirtual()
  Player.init(center.w, center.h)
  Bullets.init(center.w, center.h)
  Aliens.init(center.w, center.h)
  -- No powerup initialization in economy system
  Events.init(center.w, center.h)
  Particles.init()
  enemyFireCooldown = 0
  -- Apply difficulty-based player bonus lives for Easy
  setWave(1, false)
  local cfg = require('src.game.waves').configFor(wave)
  if cfg.playerLivesBonus and cfg.playerLivesBonus > 0 then
    Player.lives = Player.lives + cfg.playerLivesBonus
  end
  intermissionPending = false
  pendingNextCfg = nil
  bossSpawned = false
  waveGraceTimer = 1.0
end

function Game.update(dt, input)
  if isGameOver then return end

  -- No temporary upgrade overlay in economy system

  Player.update(dt, input, function(x, y, dy, from, dmg)
    Bullets.spawn(x, y, dy, from, dmg)
  end)

  Bullets.update(dt)
  -- No powerup updates in economy system
  Events.update(dt, wave)
  Particles.update(dt)
  Banner.update(dt)
  if Boss.exists() then Boss.update(dt) end

  local bottom = Aliens.update(dt)
  local px, py, pw, ph = Player.getAABB()
  local playerCenterX = px + pw/2
  local playerCenterY = py + ph/2

  -- Collisions: bullets vs aliens (and boss)
  Bullets.eachActive(function(bullet)
    if bullet.from == 'player' then
      local got = Aliens.checkBulletCollision(bullet)
      local hitBoss = false
      if not got and Boss.exists() then
        local bx, by, bw, bh = Boss.aabb()
        if bx then
          local dx = math.max(bx - bullet.x, 0, bullet.x - (bx + bw))
          local dy = math.max(by - bullet.y, 0, bullet.y - (by + bh))
          if dx*dx + dy*dy <= (bullet.radius*bullet.radius) then
            hitBoss = true
            if Boss.hit(bullet.damage or 1) then
              score = score + 250
              -- Award health bonus for boss kill
              Player.lives = math.min(Player.lives + 1, 5) -- Cap at 5 lives
              Particles.burst(bx + bw/2, by + bh/2, {1.0, 0.182, 0.651, 1.0}, 36, 280)
              Screenshake.add(0.22, 18)
              -- Visual feedback for health bonus
              Particles.burst(bx + bw/2, by + bh/2, {0.2, 1.0, 0.2, 1.0}, 20, 180) -- Green health burst
              require('src.audio.audio').play('health_bonus')
              Banner.trigger("BOSS DEFEATED! +1 LIFE")
            else
              Particles.burst(bullet.x, bullet.y, {1.0, 1.0, 1.0, 1.0}, 12, 200)
              Screenshake.add(0.06, 4)
            end
          end
        end
      end
      if got then
        score = score + got
        -- Only deactivate bullet if not piercing or has reached pierce limit
        if bullet.piercing <= 0 or #bullet.enemiesPierced >= bullet.piercing then
          bullet.active = false
        end
        Particles.burst(bullet.x, bullet.y, {1.0, 0.182, 0.651, 1.0}, 10, 220) -- magenta burst
        Screenshake.add(0.08, 4)
        require('src.audio.audio').play('hit')
        -- Award credits for alien kill (got contains the score value)
        local credits = 10 -- Base credits
        
        -- Check if this was a special alien by looking at the score value
        -- Special aliens have higher scores: tank=25, speedy=20, sniper=30, ghost=35
        if got > 15 then -- Basic alien score is 10
          credits = credits + Constants.ECONOMY.specialAlienBonus
          Economy.awardSpecialAlienKill()
        end
        
        Economy.addCredits(credits)
      elseif hitBoss then
        -- Only deactivate bullet if not piercing
        if not bullet.piercing then
          bullet.active = false
        end
      end
    end
  end)

  -- Note: Cosmetics are unlocked via credits in the economy system, not score-based unlocks

  -- Enemy fire logic (difficulty-aware)
  local cfg = Waves.configFor(wave)
  local enemyFireRate = cfg.enemyFireRate
  enemyFireCooldown = enemyFireCooldown - dt
  while enemyFireCooldown <= 0 do
    local shooter = Aliens.getRandomAliveWorld()
    if not shooter then break end
    local alienInfo = shooter.alien

    -- Check if shooter is sniper variant for increased fire rate
    local fireRateBonus = 0
    if alienInfo and alienInfo.variant == "sniper" then
      local variant = Constants.ALIEN_VARIANTS.sniper
      fireRateBonus = variant.fireRateBonus or 0
    end

    local extraDelay = Aliens.fireVariantShot(alienInfo, shooter.x, shooter.y + 8, playerCenterX, playerCenterY) or 0
    enemyFireCooldown = enemyFireCooldown + (1 / (enemyFireRate + fireRateBonus)) + extraDelay
  end

  -- Collisions: enemy bullets vs player
  Bullets.eachActive(function(b)
    if b.from == 'enemy' then
      if Player.isVulnerable() then
        local dx = math.max(px - b.x, 0, b.x - (px + pw))
        local dy = math.max(py - b.y, 0, b.y - (py + ph))
        if dx*dx + dy*dy <= (b.radius*b.radius) then
          b.active = false
          Player.lives = math.max(0, (Player.lives or 3) - 1)
          Particles.burst(b.x, b.y, {0.153, 0.953, 1.0, 1.0}, 16, 240) -- cyan
          Particles.burst(px+pw/2, py+ph/2, {1.0, 1.0, 1.0, 1.0}, 24, 260)
          Screenshake.add(0.18, 12)
          Player.startRespawn()
          if Player.lives <= 0 then
            -- Convert final score to credits
            local Economy = require("src.systems.economy")
            Economy.convertScore(score)
            isGameOver = true
          end
          require('src.audio.audio').play('hit')
        end
      end
    end
  end)

  -- Check laser boss collision
  if Boss.exists() then
    local LaserBoss = require("src.game.boss.laser")
    local laserData = LaserBoss.getLaserData and LaserBoss.getLaserData()
    if laserData and laserData.state == "firing" and Player.isVulnerable() then
      -- Check if player line intersects with laser
      local playerCenterX = px + pw/2
      local playerCenterY = py + ph/2
      
      -- Simple distance from line check
      local lineStartX, lineStartY = laserData.x, laserData.y
      local lineEndX = laserData.x + math.cos(laserData.laserAngle) * laserData.laserLength
      local lineEndY = laserData.y + math.sin(laserData.laserAngle) * laserData.laserLength
      
      -- Calculate distance from point to line
      local A = playerCenterX - lineStartX
      local B = playerCenterY - lineStartY
      local C = lineEndX - lineStartX
      local D = lineEndY - lineStartY
      
      local dot = A * C + B * D
      local lenSq = C * C + D * D
      local param = -1
      
      if lenSq ~= 0 then
        param = dot / lenSq
      end
      
      local xx, yy
      if param < 0 then
        xx, yy = lineStartX, lineStartY
      elseif param > 1 then
        xx, yy = lineEndX, lineEndY
      else
        xx = lineStartX + param * C
        yy = lineStartY + param * D
      end
      
      local dx = playerCenterX - xx
      local dy = playerCenterY - yy
      local distance = math.sqrt(dx * dx + dy * dy)
      
      if distance < (laserData.laserWidth + math.max(pw, ph)/2) then
        Player.lives = math.max(0, (Player.lives or 3) - 1)
        Particles.burst(playerCenterX, playerCenterY, {0, 0.8, 1, 1.0}, 20, 300) -- cyan laser hit
        Screenshake.add(0.3, 20)
        Player.startRespawn()
        if Player.lives <= 0 then
          isGameOver = true
        end
        require('src.audio.audio').play('hit')
      end
    end
  end

  -- Check event collisions with player
  local playerCenterX = px + pw/2
  local playerCenterY = py + ph/2
  local playerRadius = math.max(pw, ph) / 2
  if Events.checkPlayerCollisions(playerCenterX, playerCenterY, playerRadius) then
    Player.lives = math.max(0, (Player.lives or 3) - 1)
    Particles.burst(playerCenterX, playerCenterY, {1.0, 0.4, 0.2, 1.0}, 20, 300) -- Orange
    Screenshake.add(0.25, 15)
    Player.startRespawn()
    if Player.lives <= 0 then
      isGameOver = true
    end
    require('src.audio.audio').play('hit')
  end

  -- No powerup collision checking in economy system

  -- Check lose (aliens reach bottom) with grace at wave start
  if waveGraceTimer > 0 then
    waveGraceTimer = math.max(0, waveGraceTimer - dt)
  else
    local _, playerY = Player.x, Player.y
    if bottom >= playerY - 40 then
      isGameOver = true
    end
  end

  -- Wave clear / Boss spawn
  local cfg = Waves.configFor(wave)
  if cfg.boss then
    -- In boss wave
    if bossSpawned then
      -- Wait for boss defeat to progress
      if not Boss.exists() then
        -- Boss defeated -> award bonus and show intermission
        if not intermissionPending then
          local Economy = require("src.systems.economy")
          Economy.awardBossKill()
          Banner.trigger("WAVE CLEARED!")
          -- No temporary upgrade overlay - using persistent economy system
          intermissionPending = true
          pendingNextCfg = Waves.configFor(wave + 1)
          bossSpawned = false
          return

        end
      end
    else
      -- Boss not yet spawned
      if intermissionPending then
        -- Brief pause after boss defeat before next wave
        if intermissionPending and pendingNextCfg then
          setWave(wave + 1, true)
          Bullets.clear('enemy')
          Aliens.respawnFromConfig(pendingNextCfg, Player.y)
          intermissionPending = false
          pendingNextCfg = nil
          bossSpawned = false
          waveGraceTimer = 1.0
        end
        return
      end
      -- Spawn boss only after aliens cleared and no intermission pending
      if Aliens.allCleared() then
        local _, center, _ = scaling.getPanelsVirtual()
        Boss.spawnFromConfig(cfg, center.w, center.h)
        bossSpawned = true
      end
    end
  else
    -- Normal wave progression with optional upgrades intermission
    if Aliens.allCleared() then
      if not intermissionPending then
        Banner.trigger("WAVE CLEARED!")
        setWave(wave + 1, true)
        local nextCfg = Waves.configFor(wave)
        Bullets.clear('enemy')
        Aliens.respawnFromConfig(nextCfg, Player.y)
        waveGraceTimer = 1.0
      else
        -- Intermission already shown previously; wait for apply
        if not Upgrades.isShowing() and pendingNextCfg then
          setWave(wave + 1, true)
          Bullets.clear('enemy')
          Aliens.respawnFromConfig(pendingNextCfg, Player.y)
          intermissionPending = false
          pendingNextCfg = nil
          waveGraceTimer = 1.0
        end
      end
    end
  end
end

function Game.draw()
  Aliens.draw()
  Bullets.draw()
  -- No powerup drawing in economy system
  Events.draw()
  if Boss.exists() then Boss.draw() end
  Player.draw()
  Particles.draw()
  -- Banner on top, constrained to center viewport size
  local _, center, _ = scaling.getPanelsVirtual()
  Banner.draw(center.w, center.h)
end

function Game.getHUD()
  return score, Player.lives, wave
end

function Game.isOver()
  return isGameOver
end

return Game
