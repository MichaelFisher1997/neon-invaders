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
  -- Dark background
  love.graphics.setColor(0, 0, 0, 0.9)
  love.graphics.rectangle("fill", 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
  
  -- Title
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(love.graphics.newFont(48))
  love.graphics.printf("UPGRADES", 0, 40, VIRTUAL_WIDTH, "center")
  
  -- Credits display
  love.graphics.setFont(love.graphics.newFont(22))
  love.graphics.printf("Credits: " .. Economy.getCredits(), 0, 80, VIRTUAL_WIDTH, "center")
  
  -- Upgrade list
  local upgradeStartY = 120
  local upgradeHeight = 80
  local upgradeSpacing = 20
  local upgradeInfo = Economy.getUpgradeInfo()
  
  for i, upgradeType in ipairs(state.upgradeList) do
    local upgradeY = upgradeStartY + (i - 1) * (upgradeHeight + upgradeSpacing)
    local isSelected = (i == state.selectedUpgrade)
    local info = upgradeInfo[upgradeType]
    
    -- Background
    if isSelected then
      love.graphics.setColor(0.2, 0.4, 0.8, 0.8)
    else
      love.graphics.setColor(0.1, 0.2, 0.4, 0.6)
    end
    love.graphics.rectangle("fill", 100, upgradeY, VIRTUAL_WIDTH - 200, upgradeHeight)
    
    -- Border
    love.graphics.setColor(0.5, 0.7, 1.0, 1.0)
    love.graphics.rectangle("line", 100, upgradeY, VIRTUAL_WIDTH - 200, upgradeHeight)
    
    -- Upgrade name
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(22))
    love.graphics.print(info.name, 120, upgradeY + 10)
    
    -- Level indicator
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf("Level " .. info.currentLevel .. "/" .. info.maxLevel, 
                        0, upgradeY + 10, VIRTUAL_WIDTH - 120, "right")
    
    -- Description
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf(info.description, 120, upgradeY + 35, VIRTUAL_WIDTH - 240, "left")
    
    -- Cost or maxed indicator
    if info.currentLevel >= info.maxLevel then
      love.graphics.setColor(0.5, 1.0, 0.5, 1)
      love.graphics.printf("MAXED", 0, upgradeY + 55, VIRTUAL_WIDTH - 120, "right")
    elseif info.canPurchase then
      love.graphics.setColor(1.0, 1.0, 0.5, 1)
      love.graphics.printf("Cost: " .. info.cost, 0, upgradeY + 55, VIRTUAL_WIDTH - 120, "right")
    else
      love.graphics.setColor(1.0, 0.5, 0.5, 1)
      love.graphics.printf("Cost: " .. (info.cost or "N/A"), 0, upgradeY + 55, VIRTUAL_WIDTH - 120, "right")
    end
  end
  
  -- Back button
  local backButtonX = VIRTUAL_WIDTH / 2 - 60
  local backButtonY = VIRTUAL_HEIGHT - 80
  local backButtonW = 120
  local backButtonH = 40
  
  if state.backButtonHovered then
    love.graphics.setColor(0.3, 0.5, 0.9, 0.9)
  else
    love.graphics.setColor(0.2, 0.4, 0.8, 0.8)
  end
  love.graphics.rectangle("fill", backButtonX, backButtonY, backButtonW, backButtonH)
  
  love.graphics.setColor(0.5, 0.7, 1.0, 1.0)
  love.graphics.rectangle("line", backButtonX, backButtonY, backButtonW, backButtonH)
  
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(love.graphics.newFont(22))
  love.graphics.printf("BACK", backButtonX, backButtonY + 10, backButtonW, "center")
  
  -- Instructions
  love.graphics.setFont(love.graphics.newFont(16))
  love.graphics.setColor(0.7, 0.7, 0.7, 1)
  love.graphics.printf("Use ↑↓ to select, ENTER/SPACE to purchase, ESC to go back", 
                        0, VIRTUAL_HEIGHT - 30, VIRTUAL_WIDTH, "center")
  
  -- Message display
  if state.messageTimer > 0 then
    local alpha = math.min(1.0, state.messageTimer)
    love.graphics.setColor(1.0, 1.0, 0.5, alpha)
    love.graphics.setFont(love.graphics.newFont(22))
    love.graphics.printf(state.message, 0, VIRTUAL_HEIGHT / 2 - 20, VIRTUAL_WIDTH, "center")
  end
end

return UpgradeMenu