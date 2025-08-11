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
local scaling = require("src.systems.scaling")

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

function Game.init(vw, vh)
  VIRTUAL_WIDTH, VIRTUAL_HEIGHT = vw or 1280, vh or 720
  score = 0
  wave = 1
  isGameOver = false
  local _, center, _ = scaling.getPanelsVirtual()
  Player.init(center.w, center.h)
  Bullets.init(center.w, center.h)
  Aliens.init(center.w, center.h)
  Particles.init()
  enemyFireCooldown = 0
  -- Apply difficulty-based player bonus lives for Easy
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

  -- Intermission upgrade
  if Upgrades.isShowing() then
    -- freeze gameplay while choosing
    -- input handled via main keypressed (not here)
    return
  end

  Player.update(dt, input, function(x, y, dy, from, dmg)
    Bullets.spawn(x, y, dy, from, dmg)
  end)

  Bullets.update(dt)
  Particles.update(dt)
  Banner.update(dt)
  if Boss.exists() then Boss.update(dt) end

  local bottom = Aliens.update(dt)

  -- Collisions: bullets vs aliens (and boss)
  Bullets.eachActive(function(b)
    if b.from == 'player' then
      local got = Aliens.checkBulletCollision(b)
      local hitBoss = false
      if not got and Boss.exists() then
        local bx, by, bw, bh = Boss.aabb()
        if bx then
          local dx = math.max(bx - b.x, 0, b.x - (bx + bw))
          local dy = math.max(by - b.y, 0, b.y - (by + bh))
          if dx*dx + dy*dy <= (b.radius*b.radius) then
            hitBoss = true
            if Boss.hit(b.damage or 1) then
              score = score + 250
              Particles.burst(bx + bw/2, by + bh/2, {1.0, 0.182, 0.651, 1.0}, 36, 280)
              Screenshake.add(0.22, 18)
            else
              Particles.burst(b.x, b.y, {1.0, 1.0, 1.0, 1.0}, 12, 200)
              Screenshake.add(0.06, 4)
            end
          end
        end
      end
      if got then
        score = score + got
        b.active = false
        Particles.burst(b.x, b.y, {1.0, 0.182, 0.651, 1.0}, 10, 220) -- magenta burst
        Screenshake.add(0.08, 4)
        require('src.audio.audio').play('hit')
      elseif hitBoss then
        b.active = false
      end
    end
  end)

  -- Check cosmetic unlocks based on current score
  Cosmetics.checkUnlocks(score)

  -- Enemy fire logic (difficulty-aware)
  local cfg = Waves.configFor(wave)
  local enemyFireRate = cfg.enemyFireRate
  enemyFireCooldown = enemyFireCooldown - dt
  while enemyFireCooldown <= 0 do
    local shooter = Aliens.getRandomAliveWorld()
    if not shooter then break end
    Bullets.spawn(shooter.x, shooter.y + 8, 320, 'enemy', 1)
    enemyFireCooldown = enemyFireCooldown + (1 / enemyFireRate)
  end

  -- Collisions: enemy bullets vs player
  local px, py, pw, ph = Player.getAABB()
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
            isGameOver = true
          end
          require('src.audio.audio').play('hit')
        end
      end
    end
  end)

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
        -- Boss defeated -> show intermission BEFORE starting next wave
        if not intermissionPending then
          Banner.trigger("WAVE CLEARED!")
          Upgrades.show() -- always show after boss defeat
          intermissionPending = true
          pendingNextCfg = Waves.configFor(wave + 1)
          bossSpawned = false
          return
        else
          -- Intermission already shown; wait for apply/confirm
          if not Upgrades.isShowing() and pendingNextCfg then
            wave = wave + 1
            Bullets.clear('enemy')
            Aliens.respawnFromConfig(pendingNextCfg, Player.y)
            intermissionPending = false
            pendingNextCfg = nil
            bossSpawned = false
            waveGraceTimer = 1.0
          end
        end
      end
    else
      -- Boss not yet spawned
      if intermissionPending then
        -- Waiting for upgrade selection after boss defeat
        if not Upgrades.isShowing() and pendingNextCfg then
          wave = wave + 1
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
        if Upgrades.shouldShowForWave(wave) then
          Upgrades.show()
          intermissionPending = true
          pendingNextCfg = Waves.configFor(wave + 1)
          return
        else
          wave = wave + 1
          local nextCfg = Waves.configFor(wave)
          Bullets.clear('enemy')
          Aliens.respawnFromConfig(nextCfg, Player.y)
          waveGraceTimer = 1.0
        end
      else
        -- Intermission already shown previously; wait for apply
        if not Upgrades.isShowing() and pendingNextCfg then
          wave = wave + 1
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
