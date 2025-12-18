local UpgradeMenu = {}
local Constants = require("src.config.constants")
local Economy = require("src.systems.economy")
local Input = require("src.core.input")
local State = require("src.core.state")
local Fonts = require("src.ui.fonts")
local InputMode = require("src.core.inputmode")
local Neon = require("src.ui.neon_ui")

local VIRTUAL_WIDTH, VIRTUAL_HEIGHT = Constants.VIRTUAL_WIDTH, Constants.VIRTUAL_HEIGHT

local function getLayout(vw, vh)
  vw = vw or VIRTUAL_WIDTH
  vh = vh or VIRTUAL_HEIGHT
  return {
    back = { x = 20, y = 20, w = 120, h = 40 },
    list = {
      startY = vh * 0.22,
      itemHeight = 90,
      spacing = 10,
      itemWidth = 600,
      itemX = (vw - 600) / 2
    }
  }
end

-- Menu state
local state = {
  selectedUpgrade = 1,
  upgradeList = {},
  message = "",
  messageTimer = 0,
  backButtonHovered = false
}

-- Protection against accidental touches on menu entry
local justEntered = false
local entryProtectionTime = 0.5 -- 0.5s protection after menu entry

-- Initialize upgrade menu
function UpgradeMenu.init()
  state.selectedUpgrade = 1
  state.upgradeList = {}
  state.message = ""
  state.messageTimer = 0
  state.backButtonHovered = false
  
  -- Set touch delay to prevent accidental purchases
  InputMode.setTouchDelay()
  
  -- Set entry protection flag
  justEntered = true
  local startTime = love.timer.getTime()
  
  -- Get upgrade list in new order (cheapest to most expensive)
  local order = {"speed", "damage", "fireRate", "piercing", "multiShot"}
  for _, upgradeType in ipairs(order) do
    table.insert(state.upgradeList, upgradeType)
  end
end

-- Show a temporary message
local function showMessage(text)
  state.message = text
  state.messageTimer = 2.0
end

-- Handle keyboard input
function UpgradeMenu.keypressed(key)
  if key == "up" then
    state.selectedUpgrade = state.selectedUpgrade - 1
    if state.selectedUpgrade < 1 then
      state.selectedUpgrade = #state.upgradeList
    end
  elseif key == "down" then
    state.selectedUpgrade = state.selectedUpgrade + 1
    if state.selectedUpgrade > #state.upgradeList then
      state.selectedUpgrade = 1
    end
  end
  
  -- Handle purchase
  if key == "return" or key == "enter" or key == "space" then
    local upgradeType = state.upgradeList[state.selectedUpgrade]
    local success, message = Economy.purchaseUpgrade(upgradeType)
    showMessage(message)
  end
  
  -- Handle back button
  if key == "escape" then
    State.set("title") -- Return to title screen
  end
end

-- Handle input
function UpgradeMenu.update(dt)
  -- Update entry protection
  if justEntered then
    entryProtectionTime = entryProtectionTime - dt
    if entryProtectionTime <= 0 then
      justEntered = false
    end
  end
  
  -- Update message timer
  if state.messageTimer > 0 then
    state.messageTimer = state.messageTimer - dt
    if state.messageTimer <= 0 then
      state.message = ""
    end
  end
  
  -- Handle input
  local Scaling = require("src.systems.scaling")
  local mouseX, mouseY = love.mouse.getPosition()
  local scale, offsetX, offsetY = Scaling.getScale()
  local scaledX = (mouseX - offsetX) / scale
  local scaledY = (mouseY - offsetY) / scale
  
  local layout = getLayout(VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
  
  -- Back button hover
  state.backButtonHovered = (scaledX >= layout.back.x and scaledX <= layout.back.x + layout.back.w and
                             scaledY >= layout.back.y and scaledY <= layout.back.y + layout.back.h)
                             
  -- Mouse clicks
  if love.mouse.isDown(1) then
     -- Back button
     if state.backButtonHovered then
         require('src.audio.audio').play('ui_click')
         State.set("title")
         return
     end
     
     -- Upgrades
     for i, upgradeType in ipairs(state.upgradeList) do
        local upgradeY = layout.list.startY + (i - 1) * (layout.list.itemHeight + layout.list.spacing)
        if scaledX >= layout.list.itemX and scaledX <= layout.list.itemX + layout.list.itemWidth and
           scaledY >= upgradeY and scaledY <= upgradeY + layout.list.itemHeight then
           
           state.selectedUpgrade = i
           if not state.lastClickTime or (love.timer.getTime() - state.lastClickTime) > 0.5 then
              local success, msg = Economy.purchaseUpgrade(upgradeType)
              showMessage(msg)
              state.lastClickTime = love.timer.getTime()
           end
           break
        end
     end
  end
end

function UpgradeMenu.pointerPressed(vw, vh, lx, ly)
  -- Check touch delay AND entry protection to prevent accidental purchases
  if InputMode.isTouchDelayed() or justEntered then
    return nil
  end
  
  -- Handle back button
  local layout = getLayout(vw, vh)
  
  if lx >= layout.back.x and lx <= layout.back.x + layout.back.w and
     ly >= layout.back.y and ly <= layout.back.y + layout.back.h then
    require('src.audio.audio').play('ui_click')
    State.set("title")
    return nil
  end
  
  -- Handle upgrade cards
  for i, upgradeType in ipairs(state.upgradeList) do
    local upgradeY = layout.list.startY + (i - 1) * (layout.list.itemHeight + layout.list.spacing)
    
    if lx >= layout.list.itemX and lx <= layout.list.itemX + layout.list.itemWidth and
       ly >= upgradeY and ly <= upgradeY + layout.list.itemHeight then
      state.selectedUpgrade = i
      local success, message = Economy.purchaseUpgrade(upgradeType)
      showMessage(message)
      break
    end
  end
  
  return nil
end

-- Draw upgrade menu
function UpgradeMenu.draw()
  local vw, vh = VIRTUAL_WIDTH, VIRTUAL_HEIGHT
  local layout = getLayout(vw, vh)
  
  -- Background
  love.graphics.setColor(0.02, 0.02, 0.05, 1.0)
  love.graphics.rectangle("fill", 0, 0, vw, vh)
  
  -- Grid
  love.graphics.setColor(0.1, 0.1, 0.2, 0.3)
  for x = 0, vw, 50 do
    love.graphics.line(x, 0, x, vh)
  end
  for y = 0, vh, 50 do
    love.graphics.line(0, y, vw, y)
  end
  
  -- Title
  Neon.drawGlowText("UPGRADES", 0, vh * 0.04, Fonts.get(48), Neon.COLORS.white, Neon.COLORS.cyan, 1.0, 'center', vw)
  
  -- Credits
  local credits = Economy.getCredits()
  Neon.drawGlowText("Credits: " .. credits, 0, vh * 0.13, Fonts.get(24), {1, 0.9, 0.4}, {1, 0.6, 0}, 1.0, 'center', vw)
  
  -- Upgrade List
  local upgradeInfo = Economy.getUpgradeInfo()
  local upgradeColors = {
    speed = Neon.COLORS.cyan,
    damage = Neon.COLORS.red,
    fireRate = {1.0, 1.0, 0.0},
    piercing = {0.7, 0.2, 1.0},
    multiShot = {1.0, 0.6, 0.0}
  }
  
  for i, upgradeType in ipairs(state.upgradeList) do
    local upgradeY = layout.list.startY + (i - 1) * (layout.list.itemHeight + layout.list.spacing)
    local isSelected = (i == state.selectedUpgrade)
    local info = upgradeInfo[upgradeType]
    local color = upgradeColors[upgradeType] or Neon.COLORS.white
    local cardX = layout.list.itemX
    local cardW = layout.list.itemWidth
    local cardH = layout.list.itemHeight
    
    -- Card background (Glassy)
    love.graphics.setColor(0.05, 0.05, 0.1, 0.85)
    love.graphics.rectangle("fill", cardX, upgradeY, cardW, cardH, 12, 12)
    
    -- Border (Pulse if selected)
    if isSelected then
        local timer = love.timer.getTime()
        local pulse = (math.sin(timer * 5) + 1) * 0.5 * 0.5 + 0.5 
        love.graphics.setColor(color[1], color[2], color[3], pulse)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", cardX, upgradeY, cardW, cardH, 12, 12)
        
        -- Inner Glow
        love.graphics.setColor(color[1], color[2], color[3], 0.1)
        love.graphics.rectangle("fill", cardX, upgradeY, cardW, cardH, 12, 12)
    else
        love.graphics.setColor(0.3, 0.3, 0.4, 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", cardX, upgradeY, cardW, cardH, 12, 12)
    end
    love.graphics.setLineWidth(1)

    -- Icon Circle
    love.graphics.setColor(color[1], color[2], color[3], 1.0)
    love.graphics.circle("fill", cardX + 40, upgradeY + cardH/2, 25)
    
    -- Text Info
    local contentX = cardX + 80
    
    -- Name
    Neon.drawGlowText(info.name, contentX, upgradeY + 12, Fonts.get(24), Neon.COLORS.white, color, 1.0, 'left', 300)
    
    -- Level Bar
    local barX = contentX
    local barY = upgradeY + 55
    local barW = 220
    local barH = 8
    local levelRatio = info.currentLevel / info.maxLevel
    
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", barX, barY, barW, barH, 4)
    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.rectangle("fill", barX, barY, barW * levelRatio, barH, 4)
    
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.setFont(Fonts.get(14))
    love.graphics.print("Lvl " .. info.currentLevel .. "/".. info.maxLevel, barX + barW + 10, barY - 4)
    
    -- Description (Bottom)
    -- love.graphics.setColor(0.7, 0.7, 0.8, 1)
    -- love.graphics.setFont(Fonts.get(14))
    -- love.graphics.print(info.description, contentX, upgradeY + 70) 
    -- Description might be too cramped with smaller height. Let's put it top right? 
    -- Or just under name. With 90 height: 12 (name) + 24 (size) + 20 gap = 56. 
    -- Actually description is important.
    -- Let's put description small under name:
    love.graphics.setColor(0.8, 0.8, 0.9, 0.8)
    love.graphics.setFont(Fonts.get(12))
    love.graphics.print(info.description, contentX, upgradeY + 38)
    
    -- Cost / Status (Right Side)
    local costX = cardX + cardW - 100
    local costY = upgradeY + cardH/2
    
    if info.currentLevel >= info.maxLevel then
         Neon.drawGlowText("MAXED", costX - 20, costY - 10, Fonts.get(20), Neon.COLORS.cyan, Neon.COLORS.cyan, 1.0, 'center', 120)
    else
         local canAfford = credits >= info.cost
         local costColor = canAfford and {1, 1, 0.5} or {1, 0.5, 0.5}
         
         love.graphics.setFont(Fonts.get(12))
         love.graphics.setColor(0.7, 0.7, 0.7)
         love.graphics.printf("Cost", costX - 60, costY - 20, 120, "center")
         
         Neon.drawGlowText(tostring(info.cost), costX - 60, costY, Fonts.get(20), costColor, canAfford and {1, 1, 0} or {1, 0, 0}, 1.0, 'center', 120)
    end
  end

  -- Back Button
  Neon.drawButton("Back", layout.back, state.backButtonHovered, Neon.COLORS.cyan)
  
  -- Instructions
  love.graphics.setFont(Fonts.get(14))
  love.graphics.setColor(0.5, 0.5, 0.6, 1)
  if InputMode.isTouchMode() then
      love.graphics.printf("Tap to purchase", 0, vh - 30, vw, "center")
  else
      love.graphics.printf("Select with Arrows • ENTER to purchase • ESC to back", 0, vh - 30, vw, "center")
  end
  
  -- Message
  if state.messageTimer > 0 then
    local alpha = math.min(1.0, state.messageTimer)
    love.graphics.setColor(1.0, 1.0, 1.0, alpha)
    Neon.drawGlowText(state.message, 0, vh/2, Fonts.get(30), Neon.COLORS.white, Neon.COLORS.magenta, 1.0, 'center', vw)
  end
end

return UpgradeMenu
