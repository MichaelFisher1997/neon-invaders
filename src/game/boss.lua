-- Boss Manager: Handles boss selection and delegates to specific boss implementations
local BossBase = require("src.game.boss.base")

-- Import all boss types
local Shield = require("src.game.boss.shield")
local Diving = require("src.game.boss.diving")
local Splitter = require("src.game.boss.splitter")
local Laser = require("src.game.boss.laser")
local Summoner = require("src.game.boss.summoner")
local Phase = require("src.game.boss.phase")
local Turret = require("src.game.boss.turret")
local Minesweeper = require("src.game.boss.minesweeper")

local Boss = {}

-- Boss type definitions with their wave ranges
local bossTypes = {
  {name = "shield", module = Shield, startWave = 5, endWave = 9},
  {name = "diving", module = Diving, startWave = 10, endWave = 14},
  {name = "splitter", module = Splitter, startWave = 15, endWave = 19},
  {name = "laser", module = Laser, startWave = 20, endWave = 24},
  {name = "summoner", module = Summoner, startWave = 25, endWave = 29},
  {name = "phase", module = Phase, startWave = 30, endWave = 34},
  {name = "turret", module = Turret, startWave = 35, endWave = 39},
  {name = "minesweeper", module = Minesweeper, startWave = 40, endWave = 999}
}

local currentBossModule = nil

function Boss.spawnFromConfig(cfg, vw, vh)
  -- Calculate boss type based on wave progression
  local bossTypeIndex = math.floor((cfg.wave - 1) / 5) % #bossTypes + 1
  local selectedBoss = bossTypes[bossTypeIndex]
  
  -- For waves before 5, use default boss (original purple rectangle)
  if cfg.wave < 5 then
    currentBossModule = nil
    return Boss.spawnDefaultBoss(cfg, vw, vh)
  end
  
  -- Spawn the selected boss type
  currentBossModule = selectedBoss.module
  currentBossModule.spawnFromConfig(cfg, vw, vh)
end

function Boss.spawnDefaultBoss(cfg, vw, vh)
  BossBase.setVirtualSize(vw or 1280, vh or 720)
  
  -- Original boss implementation for waves 1-4
  local baseHP = 20 + 6 * cfg.wave
  local bonusHP = 2 * math.floor(cfg.wave / 10)
  local hpMax = (baseHP + bonusHP) * 3

  local data = BossBase.createBossData(cfg, 160, 64, 1.0)
  data.fireRate = 1.2 + 0.2 * math.floor(cfg.wave / 5)
  
  BossBase.setData(data)
end

function Boss.exists()
  if currentBossModule then
    return currentBossModule.exists()
  else
    return BossBase.exists()
  end
end

function Boss.update(dt)
  if currentBossModule then
    currentBossModule.update(dt)
  else
    -- Default boss update
    local data = BossBase.getData()
    if not data then return end
    
    BossBase.standardMovement(dt, 120)
    
    data.fireCooldown = data.fireCooldown - dt
    if data.fireCooldown <= 0 then
      -- Original 3-shot pattern
      local spacing = 48
      for i=-1,1 do
        -- Bullets.spawn(data.x + i*spacing, data.y + data.h/2 + 8, 380, 'enemy', 1)
      end
      data.fireCooldown = 1 / data.fireRate
    end
  end
end

function Boss.draw()
  if currentBossModule then
    currentBossModule.draw()
  else
    -- Default boss draw
    local data = BossBase.getData()
    if not data then return end
    
    -- body
    love.graphics.setColor(0.541, 0.169, 0.886, 1.0) -- purple
    love.graphics.rectangle('fill', data.x - data.w/2, data.y - data.h/2, data.w, data.h, 10, 10)
    
    -- health bar now drawn by HUD on top
  end
end

function Boss.aabb()
  if currentBossModule then
    return currentBossModule.aabb()
  else
    return BossBase.standardAABB()
  end
end

function Boss.hit(dmg)
  if currentBossModule then
    return currentBossModule.hit(dmg)
  else
    return BossBase.standardHit(dmg)
  end
end

function Boss.getMinions()
  -- For summoner boss minions
  if currentBossModule and currentBossModule.getMinions then
    return currentBossModule.getMinions()
  end
  return {}
end

function Boss.cleanup()
  if currentBossModule and currentBossModule.cleanup then
    currentBossModule.cleanup()
  else
    BossBase.cleanup()
  end
  currentBossModule = nil
end

return Boss
