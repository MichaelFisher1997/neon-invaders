local UpgradeMenu = {}
local Constants = require("src.config.constants")
local Economy = require("src.systems.economy")
local Input = require("src.core.input")
local State = require("src.core.state")

local VIRTUAL_WIDTH, VIRTUAL_HEIGHT = Constants.VIRTUAL_WIDTH, Constants.VIRTUAL_HEIGHT

-- Menu state
local state = {
  selectedUpgrade = 1,
  upgradeList = {},
  message = "",
  messageTimer = 0,
  backButtonHovered = false
}

-- Initialize upgrade menu
function UpgradeMenu.init()
  state.selectedUpgrade = 1
  state.upgradeList = {}
  state.message = ""
  state.messageTimer = 0
  state.backButtonHovered = false
  
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
  -- Update message timer
  if state.messageTimer > 0 then
    state.messageTimer = state.messageTimer - dt
    if state.messageTimer <= 0 then
      state.message = ""
    end
  end
  
  -- Handle mouse hover for back button
  local Scaling = require("src.systems.scaling")
  local mouseX, mouseY = love.mouse.getPosition()
  local scaledX = mouseX / Scaling.getScale()
  local scaledY = mouseY / Scaling.getScale()
  
  local backButtonX = VIRTUAL_WIDTH / 2 - 60
  local backButtonY = VIRTUAL_HEIGHT - 80
  local backButtonW = 120
  local backButtonH = 40
  
  state.backButtonHovered = (scaledX >= backButtonX and scaledX <= backButtonX + backButtonW and
                            scaledY >= backButtonY and scaledY <= backButtonY + backButtonH)
  
  -- Handle mouse click for upgrades
  if love.mouse.isDown(1) then
    local upgradeStartY = 120
    local upgradeHeight = 80
    local upgradeSpacing = 20
    
    for i, upgradeType in ipairs(state.upgradeList) do
      local upgradeY = upgradeStartY + (i - 1) * (upgradeHeight + upgradeSpacing)
      
      if scaledX >= 100 and scaledX <= VIRTUAL_WIDTH - 100 and
         scaledY >= upgradeY and scaledY <= upgradeY + upgradeHeight then
        state.selectedUpgrade = i
        if not state.lastClickTime or (love.timer.getTime() - state.lastClickTime) > 0.5 then
          local success, message = Economy.purchaseUpgrade(upgradeType)
          showMessage(message)
          state.lastClickTime = love.timer.getTime()
        end
        break
      end
    end
  end
  
  -- Handle mouse click for back button
  if love.mouse.isDown(1) and state.backButtonHovered then
    State.pop()
  end
end

-- Draw upgrade menu
function UpgradeMenu.draw()
  -- Neon-themed background with gradient effect
  love.graphics.setColor(0.02, 0.02, 0.05, 1.0)
  love.graphics.rectangle("fill", 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
  
  -- Subtle grid pattern for background
  love.graphics.setColor(0.1, 0.1, 0.2, 0.3)
  for x = 0, VIRTUAL_WIDTH, 50 do
    love.graphics.line(x, 0, x, VIRTUAL_HEIGHT)
  end
  for y = 0, VIRTUAL_HEIGHT, 50 do
    love.graphics.line(0, y, VIRTUAL_WIDTH, y)
  end
  
  -- Title with neon glow
  love.graphics.setColor(0.153, 0.953, 1.0, 1.0)
  love.graphics.setFont(love.graphics.newFont(48))
  local title = "UPGRADES"
  local tw = love.graphics.getFont():getWidth(title)
  love.graphics.print(title, (VIRTUAL_WIDTH - tw) / 2, 50)
  
  -- Glow effect for title
  love.graphics.setColor(0.153, 0.953, 1.0, 0.3)
  love.graphics.setFont(love.graphics.newFont(48))
  love.graphics.print(title, (VIRTUAL_WIDTH - tw) / 2 + 2, 52)
  
  -- Credits display with neon styling
  local credits = Economy.getCredits()
  love.graphics.setColor(0.5, 1.0, 0.5, 1.0)
  love.graphics.setFont(love.graphics.newFont(24))
  love.graphics.printf("CREDITS: " .. credits, 0, 100, VIRTUAL_WIDTH, "center")
  
  -- Upgrade list with enhanced styling
  local upgradeStartY = 150
  local upgradeHeight = 100
  local upgradeSpacing = 15
  local upgradeInfo = Economy.getUpgradeInfo()
  local upgradeColors = {
    speed = {0.0, 1.0, 1.0},      -- Cyan
    damage = {1.0, 0.2, 0.2},     -- Red
    fireRate = {1.0, 1.0, 0.0},   -- Yellow
    piercing = {0.5, 0.0, 1.0},   -- Purple
    multiShot = {1.0, 0.5, 0.0}   -- Orange
  }
  
  for i, upgradeType in ipairs(state.upgradeList) do
    local upgradeY = upgradeStartY + (i - 1) * (upgradeHeight + upgradeSpacing)
    local isSelected = (i == state.selectedUpgrade)
    local info = upgradeInfo[upgradeType]
    local color = upgradeColors[upgradeType] or {1, 1, 1}
    
    -- Card background with neon border
    local cardX = (VIRTUAL_WIDTH - 600) / 2  -- Center 600px wide cards
    local cardW = 600
    
    if isSelected then
      -- Selected: brighter neon background
      love.graphics.setColor(color[1], color[2], color[3], 0.2)
      love.graphics.rectangle("fill", cardX, upgradeY, cardW, upgradeHeight, 15, 15)
      love.graphics.setColor(1, 1, 1, 0.1)
      love.graphics.rectangle("fill", cardX + 5, upgradeY + 5, cardW - 10, upgradeHeight - 10, 12, 12)
    else
      -- Unselected: dark with subtle glow
      love.graphics.setColor(0.05, 0.05, 0.1, 0.8)
      love.graphics.rectangle("fill", cardX, upgradeY, cardW, upgradeHeight, 15, 15)
    end
    
    -- Outer neon border
    love.graphics.setColor(color[1], color[2], color[3], 1.0)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", cardX, upgradeY, cardW, upgradeHeight, 15, 15)
    love.graphics.setLineWidth(1)
    
    -- Inner highlight for selected
    if isSelected then
      love.graphics.setColor(1, 1, 1, 0.3)
      love.graphics.rectangle("line", cardX + 3, upgradeY + 3, cardW - 6, upgradeHeight - 6, 12, 12)
    end
    
    -- Upgrade icon (simple colored circle)
    love.graphics.setColor(color[1], color[2], color[3], 1.0)
    love.graphics.circle("fill", cardX + 30, upgradeY + upgradeHeight/2, 20, 20)
    
    -- Upgrade name with color accent
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(28))
    love.graphics.print(info.name, cardX + 70, upgradeY + 20)
    
    -- Level progress bar
    local levelRatio = info.currentLevel / info.maxLevel
    local barX = cardX + 70
    local barY = upgradeY + 55
    local barW = 200
    local barH = 8
    
    -- Background bar
    love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
    love.graphics.rectangle("fill", barX, barY, barW, barH, 4, 4)
    
    -- Progress fill
    love.graphics.setColor(color[1], color[2], color[3], 1.0)
    love.graphics.rectangle("fill", barX + 2, barY + 2, barW * levelRatio - 4, barH - 4, 2, 2)
    
    -- Level text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf("Level " .. info.currentLevel .. "/" .. info.maxLevel, barX + barW + 10, barY, 100, "left")
    
    -- Description
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf(info.description, cardX + 70, upgradeY + 75, cardW - 100, "left")
    
    -- Cost section
    local costX = cardX + cardW - 150
    local costY = upgradeY + 20
    if info.currentLevel >= info.maxLevel then
      love.graphics.setColor(0.5, 1.0, 0.5, 1)
      love.graphics.setFont(love.graphics.newFont(20))
      love.graphics.printf("MAXED", costX, costY, 120, "center")
    elseif info.canPurchase then
      love.graphics.setColor(1.0, 1.0, 0.5, 1)
      love.graphics.setFont(love.graphics.newFont(16))
      love.graphics.printf("Cost:", costX, costY, 120, "center")
      love.graphics.setFont(love.graphics.newFont(20))
      love.graphics.printf(info.cost, costX, costY + 25, 120, "center")
    else
      love.graphics.setColor(1.0, 0.5, 0.5, 1)
      love.graphics.setFont(love.graphics.newFont(16))
      love.graphics.printf("Insufficient", costX, costY, 120, "center")
      love.graphics.setFont(love.graphics.newFont(14))
      love.graphics.printf("Credits", costX, costY + 25, 120, "center")
    end
  end
  
  -- Back button with neon styling
  local backButtonX = VIRTUAL_WIDTH / 2 - 60
  local backButtonY = VIRTUAL_HEIGHT - 100
  local backButtonW = 120
  local backButtonH = 50
  
  if state.backButtonHovered then
    love.graphics.setColor(0.153, 0.953, 1.0, 0.8)
  else
    love.graphics.setColor(0.1, 0.1, 0.2, 0.7)
  end
  love.graphics.rectangle("fill", backButtonX, backButtonY, backButtonW, backButtonH, 12, 12)
  
  love.graphics.setColor(0.153, 0.953, 1.0, 1.0)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", backButtonX, backButtonY, backButtonW, backButtonH, 12, 12)
  love.graphics.setLineWidth(1)
  
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(love.graphics.newFont(24))
  love.graphics.printf("BACK", backButtonX, backButtonY + 15, backButtonW, "center")
  
  -- Instructions with better styling
  love.graphics.setFont(love.graphics.newFont(14))
  love.graphics.setColor(0.5, 0.8, 1.0, 0.8)
  love.graphics.printf("↑↓ Select • ENTER/SPACE Purchase • ESC Back", 
                        0, VIRTUAL_HEIGHT - 35, VIRTUAL_WIDTH, "center")
  
  -- Message display with neon styling
  if state.messageTimer > 0 then
    local alpha = math.min(1.0, state.messageTimer / 0.5) * 0.9
    love.graphics.setColor(1.0, 0.8, 0.2, alpha)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf(state.message, 0, VIRTUAL_HEIGHT / 2 - 20, VIRTUAL_WIDTH, "center")
    
    -- Glow effect
    love.graphics.setColor(1.0, 0.8, 0.2, alpha * 0.3)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf(state.message, 0, VIRTUAL_HEIGHT / 2 - 20 + 2, VIRTUAL_WIDTH, "center")
  end
end

return UpgradeMenu