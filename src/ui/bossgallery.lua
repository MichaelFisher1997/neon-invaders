local BossGallery = {}
local Fonts = require("src.ui.fonts")
local InputMode = require("src.core.inputmode")
local Neon = require("src.ui.neon_ui")

local selected = 1
local scroll = 0
local targetScroll = 0
local demoBoss = nil
local demoTimer = 0

-- Boss information database
local bossInfo = {
  {
    name = "Shield Boss",
    waves = "Waves 5-9",
    description = "3 shield segments protect the core. Destroy all shields to damage the main body.",
    attacks = {"Shield defense", "Spread shots", "Aimed bursts"},
    color = {0, 1, 1, 1}, -- Cyan
    module = "shield"
  },
  {
    name = "Diving Boss", 
    waves = "Waves 10-14",
    description = "Moves horizontally and periodically dives toward the player. Drops bombs during dives.",
    attacks = {"Fast aimed shots", "Shotgun bursts", "Dive bombs"},
    color = {1, 0.5, 0.2, 1}, -- Orange
    module = "diving"
  },
  {
    name = "Splitter Boss",
    waves = "Waves 15-19", 
    description = "Splits into 2-3 segments when damaged. Each segment fires different patterns.",
    attacks = {"Multi-segment", "Varied patterns", "Coordinated attacks"},
    color = {0.2, 1, 0.2, 1}, -- Green
    module = "splitter"
  },
  {
    name = "Laser Boss",
    waves = "Waves 20-24",
    description = "Charges up sweeping laser beams that damage the player. Fires mini-bursts while charging.",
    attacks = {"Sweeping laser", "Mini-bursts", "Star patterns"},
    color = {0, 0.8, 1, 1}, -- Blue
    module = "laser"
  },
  {
    name = "Summoner Boss",
    waves = "Waves 25-29",
    description = "Launches homing missiles that track player position. Missiles explode at screen bottom.",
    attacks = {"Homing missiles", "Aimed shots", "Shotgun bursts"},
    color = {0.6, 0.2, 0.8, 1}, -- Purple
    module = "summoner"
  },
  {
    name = "Phase Boss",
    waves = "Waves 30-34",
    description = "Cycles between vulnerable and invulnerable states. Different attacks per phase.",
    attacks = {"Phase cycling", "Spiral patterns", "Vulnerable windows"},
    color = {1, 0.2, 0.2, 1}, -- Red
    module = "phase"
  },
  {
    name = "Turret Boss",
    waves = "Waves 35-39",
    description = "Central core with 4 rotating turrets. 360-degree threat management required.",
    attacks = {"Rotating turrets", "Multi-directional", "Burst patterns"},
    color = {0.8, 0.8, 0.2, 1}, -- Yellow
    module = "turret"
  },
  {
    name = "Minesweeper Boss",
    waves = "Waves 40+",
    description = "Erratic movement with proximity mines. Spatial awareness and planning required.",
    attacks = {"Proximity mines", "Erratic movement", "Dense patterns"},
    color = {1, 0.2, 0.8, 1}, -- Magenta
    module = "minesweeper"
  }
}

local function getLayout(vw, vh)
  return {
    back = { x = vw - 140, y = 20, w = 120, h = 40 },
    list = {
      x = 20,
      startY = 80,
      w = 300,
      itemHeight = 110, -- Restore height
      spacing = 10
    },
    preview = {
      x = 340,
      y = 80,
      w = vw - 360, -- Remaining width
      h = vh - 160
    }
  }
end

function BossGallery.enter()
  selected = 1
  scroll = 0
  targetScroll = 0
  demoTimer = 0
  -- Initialize demo boss
  BossGallery.spawnDemoBoss(1)
end

function BossGallery.spawnDemoBoss(index)
  local info = bossInfo[index]
  if not info then return end
  
  -- Clean up previous demo boss
  if demoBoss then
    require("src.game.boss." .. demoBoss).cleanup()
  end
  
  -- Clear bullets from previous demo
  local Bullets = require("src.game.bullets")
  Bullets.clear()
  
  -- Create demo configuration
  local demoCfg = {
    wave = (index - 1) * 5 + 5, -- Use appropriate wave
  }
  
  -- Spawn the boss for demo
  local BossModule = require("src.game.boss." .. info.module)
  BossModule.spawnFromConfig(demoCfg, 1280, 720)
  
  -- Reposition boss for gallery display (top like in-game)
  local BossBase = require("src.game.boss.base")
  local data = BossBase.getData()
  if data then
    -- Use virtual dimensions for consistent positioning
    local vw, vh = BossBase.getVirtualSize()
    data.x = vw / 2      -- Center horizontally
    data.y = 140         -- Position at top like in waves
    data.galleryMode = true  -- Hide health bar in gallery
    
    -- Special handling for different boss types in gallery
    if info.module == "minesweeper" then
      -- Minesweeper boss needs to move to show its behavior
      data.speed = 180   -- Restore movement speed for visibility
      data.baseSpeed = 180 -- Ensure phase movement works
      -- Use the same starting position as in-game for proper mine placement
      data.x = 50 -- Match sweepStartX for correct mine spacing
      data.dir = 1
    elseif info.module == "splitter" then
      data.speed = 0       -- Keep stationary for other bosses
      -- Special handling for Splitter boss - set health to trigger split after 5s
      data.gallerySplitTimer = 5.0 -- 5 seconds before auto-split
    else
      data.speed = 0       -- Keep stationary for gallery
    end
  end
  
  -- Set up mock player position for targeting (bottom center of screen)
  local Player = require("src.game.player")
  Player.x = BossBase.getVirtualSize() / 2
  Player.y = BossBase.getVirtualSize() - 100
  
  demoBoss = info.module
  demoTimer = 0
end

function BossGallery.update(dt)
  local BossBase = require("src.game.boss.base")
  local vw, vh = BossBase.getVirtualSize()
  local layout = getLayout(vw, vh)
  local cardStride = layout.list.itemHeight + layout.list.spacing
  
  -- Bounded smooth scrolling to always show 5-6 cards
  local visibleCards = 5
  local maxVisibleHeight = visibleCards * cardStride
  local listHeight = #bossInfo * cardStride
  local maxScroll = 0
  local minScroll = -math.max(0, listHeight - maxVisibleHeight)
  
  -- Only auto-scroll to selected boss when not manually scrolling
  if not isDragging then
    local idealScroll = -(selected - 1) * cardStride + (layout.list.itemHeight * 1.5)
    targetScroll = math.max(minScroll, math.min(maxScroll, idealScroll))
  end
  
  -- Apply smooth scrolling with momentum
  scroll = scroll + (targetScroll - scroll) * 0.15
  
  -- Apply friction to momentum scrolling
  if not isDragging and scrollVelocity then
    scrollVelocity = scrollVelocity * 0.9
    if math.abs(scrollVelocity) < 1 then
      scrollVelocity = 0
    end
  end
  
  -- Update demo boss with firing
  if demoBoss then
    demoTimer = demoTimer + dt
    
    -- Handle Splitter boss auto-split in gallery
    if demoBoss == "splitter" then
      local BossBase = require("src.game.boss.base")
      local data = BossBase.getData()
      if data and data.gallerySplitTimer then
        data.gallerySplitTimer = data.gallerySplitTimer - dt
        if data.gallerySplitTimer <= 0 and not data.splitTriggered then
          -- Trigger the split
          data.splitTriggered = true
          data.hp = 0
          data.gallerySplitTimer = nil
        end
      end
    end
    
    local BossModule = require("src.game.boss." .. demoBoss)
    if BossModule.update then
      BossModule.update(dt)
    end
    
    -- Update bullets so they move across screen
    local Bullets = require("src.game.bullets")
    Bullets.update(dt)
    
    -- Update particles for explosion effects
    local Particles = require("src.fx.particles")
    if Particles.update then
      Particles.update(dt)
    end
  end
end

function BossGallery.keypressed(key)
  if key == 'up' or key == 'w' then
    selected = math.max(1, selected - 1)
    BossGallery.spawnDemoBoss(selected)
    require('src.audio.audio').play('ui_click')
  elseif key == 'down' or key == 's' then
    selected = math.min(#bossInfo, selected + 1)
    BossGallery.spawnDemoBoss(selected)
    require('src.audio.audio').play('ui_click')
  elseif key == 'escape' then
    -- Clean up demo boss
    if demoBoss then
      require("src.game.boss." .. demoBoss).cleanup()
      demoBoss = nil
    end
    require('src.audio.audio').play('ui_click')
    return 'title'
  end
  return nil
end

function BossGallery.pointerPressed(vw, vh, lx, ly)
  local layout = getLayout(vw, vh)

  -- Check back button
  if lx >= layout.back.x and lx <= layout.back.x + layout.back.w and
     ly >= layout.back.y and ly <= layout.back.y + layout.back.h then
    if demoBoss then
      require("src.game.boss." .. demoBoss).cleanup()
      demoBoss = nil
    end
    require('src.audio.audio').play('ui_click')
    return 'title'
  end
  
  -- Initialize touch tracking first for the list area
  if lx >= layout.list.x and lx <= layout.list.x + layout.list.w and ly >= layout.list.startY then
    touchStartY = ly
    touchStartTime = love.timer.getTime()
    isDragging = false  -- Don't start dragging immediately
    scrollVelocity = 0
  end
  
  return nil
end

-- Touch scrolling state
local touchStartY = nil
local touchStartTime = nil
local scrollVelocity = 0
local isDragging = false
local dragThreshold = 8  -- Minimum movement to start scrolling

function BossGallery.pointerMoved(vw, vh, lx, ly)
  if touchStartY then
    local deltaY = ly - touchStartY
    
    -- Check if we've moved enough to start scrolling
    if not isDragging and math.abs(deltaY) > dragThreshold then
      isDragging = true
    end
    
    if isDragging then
      scroll = scroll + deltaY
      
      -- Apply boundaries
      local layout = getLayout(vw, vh)
      local cardStride = layout.list.itemHeight + layout.list.spacing
      local visibleCards = 5
      local listHeight = #bossInfo * cardStride
      local maxScroll = 0
      local minScroll = -math.max(0, listHeight - visibleCards * cardStride)
      scroll = math.max(minScroll, math.min(maxScroll, scroll))
      
      touchStartY = ly
      scrollVelocity = deltaY  -- Track velocity for momentum
      targetScroll = scroll  -- Update target scroll immediately for responsive feel
    end
  end
  return nil
end

function BossGallery.pointerReleased(vw, vh, lx, ly)
  if touchStartY then
    local touchDuration = love.timer.getTime() - (touchStartTime or 0)
    local layout = getLayout(vw, vh)
    local cardStride = layout.list.itemHeight + layout.list.spacing
    
    if not isDragging and touchDuration < 0.3 and touchDuration > 0.05 then
      -- This was a tap - check what was tapped
      local cardX = layout.list.x
      local cardWidth = layout.list.w
      local cardHeight = layout.list.itemHeight
      local cardStartY = layout.list.startY + scroll
      
      for i, info in ipairs(bossInfo) do
        local cardY = cardStartY + (i - 1) * cardStride
        local card = {x = cardX, y = cardY, w = cardWidth, h = cardHeight}
        if lx >= card.x and lx <= card.x + card.w and
           ly >= card.y and ly <= card.y + card.h then
          selected = i
          BossGallery.spawnDemoBoss(selected)
          require('src.audio.audio').play('ui_click')
          break
        end
      end
    else
      -- This was a drag - apply momentum based on scroll velocity
      if touchDuration < 0.3 and math.abs(scrollVelocity) > 50 then
         -- Quick swipe - apply momentum
         targetScroll = scroll + scrollVelocity * 0.5
      else
         -- Slow drag - snap to position
         targetScroll = scroll
      end
      
      -- Apply boundaries to target
      local visibleCards = 5
      local listHeight = #bossInfo * cardStride
      local maxScroll = 0
      local minScroll = -math.max(0, listHeight - visibleCards * cardStride)
      targetScroll = math.max(minScroll, math.min(maxScroll, targetScroll))
    end
  end
  
  touchStartY = nil
  touchStartTime = nil
  scrollVelocity = 0
  isDragging = false
  return nil
end



function BossGallery.draw(vw, vh)
  local layout = getLayout(vw, vh)

  -- Background
  love.graphics.setColor(0.02, 0.02, 0.05, 1.0)
  love.graphics.rectangle('fill', 0, 0, vw, vh)
  
  -- Preview Area Frame (Subtle)
  -- love.graphics.setColor(0.1, 0.1, 0.2, 0.3)
  -- love.graphics.rectangle('line', layout.preview.x, layout.preview.y, layout.preview.w, layout.preview.h, 12, 12)
  
  -- Draw demo boss and bullets (Before UI so they are behind/integrated)
  if demoBoss then
    -- Draw boss at full opacity
    love.graphics.setColor(1, 1, 1, 1.0)
    
    local BossModule = require("src.game.boss." .. demoBoss)
    if BossModule.draw then
      BossModule.draw()
    end
    
    -- Draw bullets
    local Bullets = require("src.game.bullets")
    Bullets.draw()
    
    -- Draw particles for explosion effects
    local Particles = require("src.fx.particles")
    if Particles.draw then
      Particles.draw()
    end
  end
  
  -- Title
  Neon.drawGlowText("BOSS GALLERY", 0, vh * 0.04, Fonts.get(48), Neon.COLORS.white, Neon.COLORS.cyan, 1.0, 'center', vw)
  
  -- Back button
  Neon.drawButton("Back", layout.back, false, Neon.COLORS.cyan)
  
  -- Boss cards - draw on left side
  -- Clip list to screen height within reasonable bounds
   --love.graphics.setScissor(layout.list.x, layout.list.startY - 20, layout.list.w, vh - layout.list.startY + 20)
  
  -- Actually, with back button moved, we don't need aggressive top clipping, just screen boundaries
  -- But let's keep it tidy
  love.graphics.setScissor(0, 0, vw, vh)
  
  for i, info in ipairs(bossInfo) do
    local cardY = layout.list.startY + (i - 1) * (layout.list.itemHeight + layout.list.spacing) + scroll
    
    -- Only draw if card is within reasonable bounds (optimization)
    if cardY >= -200 and cardY <= vh + 200 then
      local card = {x = layout.list.x, y = cardY, w = layout.list.w, h = layout.list.itemHeight}
      local isSelected = (i == selected)
      local color = info.color or Neon.COLORS.cyan
      
      -- Card background (Glassy)
      love.graphics.setColor(0.05, 0.05, 0.1, 0.85)
      love.graphics.rectangle("fill", card.x, card.y, card.w, card.h, 12, 12)
      
      -- Border (Pulse if selected)
      if isSelected then
          local timer = love.timer.getTime()
          local pulse = (math.sin(timer * 5) + 1) * 0.5 * 0.5 + 0.5 
          love.graphics.setColor(color[1], color[2], color[3], pulse)
          love.graphics.setLineWidth(3)
          love.graphics.rectangle("line", card.x, card.y, card.w, card.h, 12, 12)
          
          -- Inner Glow
          love.graphics.setColor(color[1], color[2], color[3], 0.1)
          love.graphics.rectangle("fill", card.x, card.y, card.w, card.h, 12, 12)
      else
          love.graphics.setColor(0.3, 0.3, 0.4, 0.5)
          love.graphics.setLineWidth(1)
          love.graphics.rectangle("line", card.x, card.y, card.w, card.h, 12, 12)
      end
      love.graphics.setLineWidth(1)
      
      -- Boss icon (colored square -> circle/glow)
      love.graphics.setColor(color[1], color[2], color[3], 1.0)
      love.graphics.circle("fill", card.x + 25, card.y + 25, 12)
      
      -- Boss name
      -- Neon.drawGlowText(info.name, card.x + 50, card.y + 12, Fonts.get(18), Neon.COLORS.white, color, 1.0, 'left', 200)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.setFont(Fonts.get(18))
      love.graphics.print(info.name, card.x + 50, card.y + 15)

      -- Waves
      love.graphics.setFont(Fonts.get(12))
      love.graphics.setColor(0.7, 0.7, 0.7, 1.0)
      love.graphics.print(info.waves, card.x + 50, card.y + 35)
      
      -- Description (shortened)
      love.graphics.setColor(0.8, 0.8, 0.9, 0.9)
      love.graphics.setFont(Fonts.get(12))
      love.graphics.printf(info.description, card.x + 10, card.y + 55, card.w - 20, 'left')
    end
  end
  
  -- Reset scissor
  love.graphics.setScissor()
  
  -- Navigation hint
  love.graphics.setFont(Fonts.get(14))
  love.graphics.setColor(0.5, 0.8, 1.0, 0.8)
  local y = vh - 25
  if InputMode.isTouchMode() then
     love.graphics.printf("Tap to select • Swipe list to scroll", 0, y, vw, "center")
  else
     love.graphics.printf("Arrows/WASD to browse • ESC Return", 0, y, vw, "center")
  end
end

return BossGallery