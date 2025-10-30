-- Splitter Boss: Multiple target management
-- Waves 15-19: Splits into 2-3 segments when damaged, each segment fires different patterns
local BossBase = require("src.game.boss.base")
local Bullets = require("src.game.bullets")

local Splitter = {}

function Splitter.spawnFromConfig(cfg, vw, vh)
  BossBase.setVirtualSize(vw, vh)
  
  local data = BossBase.createBossData(cfg, 160, 70, 1.2)
  data.segments = {
    {x = data.x - 30, y = data.y, w = 50, h = 50, hp = math.floor(data.hpMax * 0.3), hpMax = math.floor(data.hpMax * 0.3), fireCooldown = 0},
    {x = data.x, y = data.y, w = 60, h = 60, hp = math.floor(data.hpMax * 0.4), hpMax = math.floor(data.hpMax * 0.4), fireCooldown = 0},
    {x = data.x + 30, y = data.y, w = 50, h = 50, hp = math.floor(data.hpMax * 0.3), hpMax = math.floor(data.hpMax * 0.3), fireCooldown = 0}
  }
  data.splitTriggered = false
  data.splitThreshold = data.hpMax * 0.6 -- Split when health drops below 60%
  data.mainSegmentIndex = 2 -- Center segment is the main one
  
  BossBase.setData(data)
end

function Splitter.exists()
  return BossBase.exists()
end

function Splitter.update(dt)
  local data = BossBase.getData()
  if not data then return end
  
  -- Check if we should split
  if not data.splitTriggered and data.hp <= data.splitThreshold then
    data.splitTriggered = true
    -- Main boss becomes invisible, segments become individual entities
    data.hp = 0
  end
  
  -- If split, update individual segments
  if data.splitTriggered then
    for i, segment in ipairs(data.segments) do
      if segment.hp > 0 then
        -- Individual segment movement (slight independent movement)
        local offset = math.sin(love.timer.getTime() * 2 + i) * 20
        local baseX = data.x + (i - 2) * 60 -- Spread out the segments
        segment.x = baseX + offset
        
        -- Individual segment firing
        segment.fireCooldown = segment.fireCooldown - dt
        if segment.fireCooldown <= 0 then
          if i == 1 then
            -- Left segment: aimed shots with spread
            BossBase.shotgunBurst(segment.x, segment.y + segment.h/2, math.pi/6, 3, 300, 0.8)
          elseif i == 2 then
            -- Center segment: rapid aimed shots
            BossBase.aimedShot(segment.x, segment.y + segment.h/2, 400, 1)
          elseif i == 3 then
            -- Right segment: star pattern
            BossBase.starPattern(segment.x, segment.y + segment.h/2, 6, 280, 0.6)
          end
          segment.fireCooldown = 0.8 + math.random() * 0.3
        end
      end
    end
  else
    -- Pre-split: normal boss behavior
    BossBase.standardMovement(dt, 80)
    
    data.fireCooldown = data.fireCooldown - dt
    if data.fireCooldown <= 0 then
      -- Mix of patterns before splitting
      local attackType = math.random(3)
      if attackType == 1 then
        -- Standard 3-shot pattern
        local spacing = 48
        for i=-1,1 do
          Bullets.spawn(data.x + i*spacing, data.y + data.h/2 + 8, 350, 'enemy', 1)
        end
      elseif attackType == 2 then
        -- Aimed burst
        BossBase.aimedShot(data.x, data.y + data.h/2 + 8, 380, 1)
      else
        -- Small star
        BossBase.starPattern(data.x, data.y + data.h/2 + 8, 5, 320, 0.8)
      end
      data.fireCooldown = 1.0
    end
  end
end

function Splitter.draw()
  local data = BossBase.getData()
  if not data then return end
  
  if data.splitTriggered then
    -- Draw individual segments
    local colors = {
      {0.2, 0.8, 0.2, 1.0}, -- Left: green
      {0.3, 0.9, 0.3, 1.0}, -- Center: bright green
      {0.2, 0.8, 0.2, 1.0}  -- Right: green
    }
    
    for i, segment in ipairs(data.segments) do
      if segment.hp > 0 then
        -- Draw segment
        love.graphics.setColor(unpack(colors[i]))
        love.graphics.rectangle('fill', segment.x - segment.w/2, segment.y - segment.h/2, segment.w, segment.h, 8, 8)
        
        -- Draw segment health bar
        local ratio = segment.hp / segment.hpMax
        love.graphics.setColor(1,1,1,1)
        love.graphics.rectangle('line', segment.x - 20, segment.y + segment.h/2 + 5, 40, 4)
        love.graphics.setColor(0.2, 0.8, 0.2, 1)
        love.graphics.rectangle('fill', segment.x - 18, segment.y + segment.h/2 + 7, 36 * ratio, 2)
      end
    end
  else
    -- Draw pre-split boss (green composite)
    love.graphics.setColor(0.3, 0.9, 0.3, 1.0)
    love.graphics.rectangle('fill', data.x - data.w/2, data.y - data.h/2, data.w, data.h, 10, 10)
  end
  
  -- Draw health bar for main boss (or combined if split)
  if not data.splitTriggered then
    BossBase.drawHealthBar()
  end
end

function Splitter.hit(dmg)
  local data = BossBase.getData()
  if not data then return false end
  
  if data.splitTriggered then
    -- Hit individual segments - find the closest one to the hit point
    -- For simplicity, cycle through segments
    for i, segment in ipairs(data.segments) do
      if segment.hp > 0 then
        segment.hp = segment.hp - (dmg or 1)
        if segment.hp <= 0 then
          segment.hp = 0
          -- Check if all segments are destroyed
          local allDead = true
          for _, seg in ipairs(data.segments) do
            if seg.hp > 0 then
              allDead = false
              break
            end
          end
          if allDead then
            BossBase.cleanup()
            return true
          end
        end
        return false
      end
    end
  else
    -- Hit main boss before split
    data.hp = data.hp - (dmg or 1)
    return false
  end
end

function Splitter.aabb()
  local data = BossBase.getData()
  if not data then return nil end
  
  if data.splitTriggered then
    -- Return AABB of first living segment (simplified collision)
    for _, segment in ipairs(data.segments) do
      if segment.hp > 0 then
        return segment.x - segment.w/2, segment.y - segment.h/2, segment.w, segment.h
      end
    end
  else
    return BossBase.standardAABB()
  end
end

function Splitter.cleanup()
  BossBase.cleanup()
end

return Splitter