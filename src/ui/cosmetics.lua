local Cosmetics = require("src.systems.cosmetics")
local Economy = require("src.systems.economy")
local Constants = require("src.config.constants")
local audio = require("src.audio.audio")
local Fonts = require("src.ui.fonts")
local InputMode = require("src.core.inputmode")
local Neon = require("src.ui.neon_ui")

local UICosmetics = {}

-- State management
local state = {
  tab = "colors", -- "colors" or "shapes"
  colorSelection = 1,
  shapeSelection = 1,
  colorScroll = 0,
  shapeScroll = 0,
  message = "",
  messageTimer = 0
}

-- Touch scrolling state
local touchStartY = nil
local touchStartTime = nil
local scrollVelocity = 0
local isDragging = false
local currentScroll = 0  -- Track which scroll we're modifying

-- Double tap detection
local lastTapTime = 0
local lastTapX = 0
local lastTapY = 0
local doubleTapThreshold = 0.3  -- 300ms for double tap
local doubleTapDistance = 50   -- Max distance for double tap

-- Dynamic RGB preview (faster!)
local function rgbTripColor(time)
  local t = time * 2.5
  local r = 0.5 + 0.5 * math.sin(t)
  local g = 0.5 + 0.5 * math.sin(t + 2.0944)
  local b = 0.5 + 0.5 * math.sin(t + 4.1888)
  return { r, g, b, 1.0 }
end

local function showMessage(text)
  state.message = text
  state.messageTimer = 2.0
end

local function getColors()
  local colors = {}
  if Constants.ECONOMY and Constants.ECONOMY.cosmetics and Constants.ECONOMY.cosmetics.colors then
    for id, color in pairs(Constants.ECONOMY.cosmetics.colors) do
      if color and id and type(color) == "table" then  -- Only add valid entries
        color.id = id
        table.insert(colors, color)
      end
    end
  end
  return colors
end

local function getShapes()
  local shapes = {}
  if Constants.ECONOMY and Constants.ECONOMY.cosmetics and Constants.ECONOMY.cosmetics.shapes then
    for id, shape in pairs(Constants.ECONOMY.cosmetics.shapes) do
      if shape and id and type(shape) == "table" then  -- Only add valid entries
        shape.id = id
        table.insert(shapes, shape)
      end
    end
  end
  return shapes
end

local function getLayout(vw, vh)
  -- Safety check for valid dimensions
  if not vw or not vh or vw <= 0 or vh <= 0 then
    vw, vh = love.graphics.getDimensions()
  end
  
  local tabButtonsY = vh * 0.20
  local tabButtonW = 120
  local tabButtonH = 40
  local colorsTabX = vw/2 - tabButtonW - 10
  local shapesTabX = vw/2 + 10
  
  local itemStartY = vh * 0.28
  local itemHeight = 80
  local itemSpacing = 10
  local itemWidth = math.min(450, vw * 0.8)
  local itemX = (vw - itemWidth) / 2
  
  -- Show only 5 items at once, or fewer if height is small
  local visibleItems = 5
  local listHeight = visibleItems * itemHeight + (visibleItems - 1) * itemSpacing
  
  local backW, backH = 120, 40
  local backX = (vw - backW) / 2
  local backY = vh - 80
  
  return {
    tabButtons = {
      colors = { x = colorsTabX, y = tabButtonsY, w = tabButtonW, h = tabButtonH },
      shapes = { x = shapesTabX, y = tabButtonsY, w = tabButtonW, h = tabButtonH }
    },
    items = {
      startY = itemStartY,
      height = itemHeight,
      spacing = itemSpacing,
      width = itemWidth,
      x = itemX,
      visibleCount = visibleItems,
      listHeight = listHeight
    },
    back = { x = backX, y = backY, w = backW, h = backH }
  }
end

local function drawColorItem(layout, item, index, isSelected, displayIndex)
  local y = layout.items.startY + (displayIndex - 1) * (layout.items.height + layout.items.spacing)
  local rect = { x = layout.items.x, y = y, w = layout.items.width, h = layout.items.height }
  
  local isUnlocked = Cosmetics.isColorUnlocked(item.id)
  local isEquipped = Cosmetics.getSelectedColor() == item.id
  
  -- Use Neon Button style for the item container
  -- If selected, it pulses. If not, it's a static glass panel.
  local borderColor = isSelected and Neon.COLORS.cyan or {0.3, 0.3, 0.4}
  local backColor = {0.05, 0.05, 0.1, 0.8}
  
  -- Glass Background
  love.graphics.setColor(unpack(backColor))
  love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 12, 12)
  
  -- Border
  if isSelected then
    -- Pulsing border for selection
    local pulse = (math.sin(love.timer.getTime() * 5) + 1) * 0.5 * 4
    love.graphics.setColor(Neon.COLORS.cyan[1], Neon.COLORS.cyan[2], Neon.COLORS.cyan[3], 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", rect.x - pulse, rect.y - pulse, rect.w + pulse*2, rect.h + pulse*2, 12 + pulse, 12 + pulse)
    
    love.graphics.setColor(Neon.COLORS.cyan)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 12, 12)
  else
    -- Dim border for unselected
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 12, 12)
  end
  
  -- Color preview
  local previewColor
  if item.id == 'rgb_trip' then
    previewColor = rgbTripColor(love.timer.getTime())
  else
    previewColor = item.color or {1,1,1,1}
  end
  
  -- Glow behind preview
  love.graphics.setColor(previewColor[1], previewColor[2], previewColor[3], 0.3)
  love.graphics.circle("fill", rect.x + 40, rect.y + rect.h/2, 28)
  
  -- Actual preview circle
  love.graphics.setColor(previewColor)
  love.graphics.circle("fill", rect.x + 40, rect.y + rect.h/2, 20)
  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.circle("line", rect.x + 40, rect.y + rect.h/2, 20)
  
  -- Text
  love.graphics.setColor(Neon.COLORS.white)
  love.graphics.setFont(Fonts.get(22))
  love.graphics.print(item.name, rect.x + 85, rect.y + 12)
  
  love.graphics.setFont(Fonts.get(16))
  love.graphics.setColor(0.7, 0.7, 0.7, 1)
  love.graphics.print(item.description, rect.x + 85, rect.y + 40)
  
  -- Status (Right aligned)
  local statusX = rect.x + rect.w - 15
  local statusY = rect.y + 25
  
  if isUnlocked then
    if isEquipped then
      Neon.drawGlowText("EQUIPPED", statusX - 100, statusY - 10, Fonts.get(18), Neon.COLORS.cyan, Neon.COLORS.cyan, 1.0, 'right', 100)
    else
      love.graphics.setColor(0.5, 0.5, 0.5, 1)
      love.graphics.setFont(Fonts.get(16))
      love.graphics.printf("OWNED", rect.x, statusY, rect.w - 20, "right")
    end
  else
    love.graphics.setColor(1.0, 0.9, 0.3, 1)
    love.graphics.setFont(Fonts.get(16))
    love.graphics.printf(item.cost .. " CR", rect.x, statusY, rect.w - 20, "right")
  end
end

local function drawShapeItem(layout, item, index, isSelected, displayIndex)
  local y = layout.items.startY + (displayIndex - 1) * (layout.items.height + layout.items.spacing)
  local rect = { x = layout.items.x, y = y, w = layout.items.width, h = layout.items.height }
  
  local isUnlocked = Cosmetics.isShapeUnlocked(item.id)
  local isEquipped = Cosmetics.getSelectedShape() == item.id
  
  local backColor = {0.05, 0.05, 0.1, 0.8}
  
  -- Glass Background
  love.graphics.setColor(unpack(backColor))
  love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 12, 12)
  
  -- Border
  if isSelected then
    -- Pulsing border for selection
    local pulse = (math.sin(love.timer.getTime() * 5) + 1) * 0.5 * 4
    love.graphics.setColor(Neon.COLORS.cyan[1], Neon.COLORS.cyan[2], Neon.COLORS.cyan[3], 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", rect.x - pulse, rect.y - pulse, rect.w + pulse*2, rect.h + pulse*2, 12 + pulse, 12 + pulse)
    
    love.graphics.setColor(Neon.COLORS.cyan)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 12, 12)
  else
    -- Dim border for unselected
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 12, 12)
  end
  
  -- Shape preview
  love.graphics.setColor(Cosmetics.getColor())
  local previewWidth = Constants.PLAYER.width * 2.5
  local previewHeight = Constants.PLAYER.height * 2.5
  Cosmetics.drawSpecificShape(item.id, rect.x + 40, rect.y + rect.h/2, previewWidth, previewHeight)
  
  -- Text
  love.graphics.setColor(Neon.COLORS.white)
  love.graphics.setFont(Fonts.get(22))
  love.graphics.print(item.name, rect.x + 100, rect.y + 12)
  
  love.graphics.setFont(Fonts.get(16))
  love.graphics.setColor(0.7, 0.7, 0.7, 1)
  love.graphics.print(item.description, rect.x + 100, rect.y + 40)
  
  -- Status
  local statusX = rect.x + rect.w - 15
  local statusY = rect.y + 25
  
  if isUnlocked then
    if isEquipped then
      Neon.drawGlowText("EQUIPPED", statusX - 100, statusY - 10, Fonts.get(18), Neon.COLORS.cyan, Neon.COLORS.cyan, 1.0, 'right', 100)
    else
      love.graphics.setColor(0.5, 0.5, 0.5, 1)
      love.graphics.setFont(Fonts.get(16))
      love.graphics.printf("OWNED", rect.x, statusY, rect.w - 20, "right")
    end
  else
    love.graphics.setColor(1.0, 0.9, 0.3, 1)
    love.graphics.setFont(Fonts.get(16))
    love.graphics.printf(item.cost .. " CR", rect.x, statusY, rect.w - 20, "right")
  end
end

function UICosmetics.enter()
  -- Reset to first items when entering
  state.colorSelection = 1
  state.shapeSelection = 1
  state.colorScroll = 0
  state.shapeScroll = 0
  state.message = ""
  state.messageTimer = 0
end

function UICosmetics.update(dt)
  -- Update message timer
  if state.messageTimer > 0 then
    state.messageTimer = state.messageTimer - dt
    if state.messageTimer <= 0 then
      state.message = ""
    end
  end
end

function UICosmetics.draw(vw, vh)
  local layout = getLayout(vw, vh)
  local credits = Economy.getCredits()

  -- Title
  Neon.drawGlowText("Cosmetics Shop", 0, vh * 0.04, Fonts.get(48), Neon.COLORS.white, Neon.COLORS.magenta, 1.0, 'center', vw)
  
  -- Credits (Gold/Yellow for contrast)
  Neon.drawGlowText("Credits: " .. credits, 0, vh * 0.13, Fonts.get(24), {1, 0.9, 0.4}, {1, 0.6, 0}, 1.0, 'center', vw)

  -- Use layout.tabButtons for tabs

  
  -- Draw Colors Tab
  local isColorsSelected = (state.tab == "colors")
  Neon.drawButton("Colors", layout.tabButtons.colors, isColorsSelected, isColorsSelected and Neon.COLORS.cyan or Neon.COLORS.white)
  
  -- Draw Shapes Tab
  local isShapesSelected = (state.tab == "shapes")
  Neon.drawButton("Shapes", layout.tabButtons.shapes, isShapesSelected, isShapesSelected and Neon.COLORS.cyan or Neon.COLORS.white)

  -- Items List
  if state.tab == "colors" then
    local colors = getColors()
    local startIndex = math.floor(state.colorScroll) + 1
    local endIndex = math.min(startIndex + layout.items.visibleCount - 1, #colors)
    
    for displayIndex = startIndex, endIndex do
      local actualIndex = displayIndex
      if actualIndex >= 1 and actualIndex <= #colors and colors[actualIndex] then
        local isSelected = (actualIndex == state.colorSelection)
        local displayPos = displayIndex - startIndex + 1
        drawColorItem(layout, colors[actualIndex], actualIndex, isSelected, displayPos)
      end
    end
    
    -- Scroll indicators
    if #colors > layout.items.visibleCount then
      love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
      love.graphics.setFont(Fonts.get(14))
      if state.colorScroll > 0 then
        local arrowX = layout.items.x + layout.items.width/2
        local arrowY = layout.items.startY - 15
        love.graphics.polygon("fill", arrowX - 5, arrowY + 3, arrowX + 5, arrowY + 3, arrowX, arrowY - 3)
      end
      if endIndex < #colors then
        local arrowX = layout.items.x + layout.items.width/2
        local arrowY = layout.items.startY + layout.items.listHeight + 10
        love.graphics.polygon("fill", arrowX - 5, arrowY - 3, arrowX + 5, arrowY - 3, arrowX, arrowY + 3)
      end
    end
  else
    local shapes = getShapes()
    local startIndex = math.floor(state.shapeScroll) + 1
    local endIndex = math.min(startIndex + layout.items.visibleCount - 1, #shapes)
    
    for displayIndex = startIndex, endIndex do
      local actualIndex = displayIndex
      if actualIndex >= 1 and actualIndex <= #shapes and shapes[actualIndex] then
        local isSelected = (actualIndex == state.shapeSelection)
        local displayPos = displayIndex - startIndex + 1
        drawShapeItem(layout, shapes[actualIndex], actualIndex, isSelected, displayPos)
      end
    end
    
    -- Scroll indicators
    if #shapes > layout.items.visibleCount then
      love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
      love.graphics.setFont(Fonts.get(14))
      if state.shapeScroll > 0 then
        local arrowX = layout.items.x + layout.items.width/2
        local arrowY = layout.items.startY - 15
        love.graphics.polygon("fill", arrowX - 5, arrowY + 3, arrowX + 5, arrowY + 3, arrowX, arrowY - 3)
      end
      if endIndex < #shapes then
        local arrowX = layout.items.x + layout.items.width/2
        local arrowY = layout.items.startY + layout.items.listHeight + 10
        love.graphics.polygon("fill", arrowX - 5, arrowY - 3, arrowX + 5, arrowY - 3, arrowX, arrowY + 3)
      end
    end
  end
  
  -- Back Button
  local backRect = layout.back
  Neon.drawButton("Back", backRect, false, Neon.COLORS.cyan) -- Always show as static button for now
  
  -- Instructions
  love.graphics.setFont(Fonts.get(14))
  love.graphics.setColor(0.7, 0.7, 0.7, 1)
  local y = vh - 30
  
  if InputMode.isTouchMode() then
     love.graphics.printf("Touch: Single tap to select, Double-tap to purchase/equip, Swipe to scroll", 0, y, vw, "center")
  else
     love.graphics.printf("Use UP/DOWN arrows to select, ENTER to purchase/equip, TAB to switch tabs, ESC to go back", 0, y, vw, "center")
  end
  
  -- Message display
  if state.messageTimer > 0 then
    local alpha = math.min(1.0, state.messageTimer)
    love.graphics.setColor(1.0, 1.0, 0.5, alpha)
    local msgY = vh * 0.85
    Neon.drawGlowText(state.message, vw/2 - 200, msgY, Fonts.get(24), Neon.COLORS.white, Neon.COLORS.cyan, 1.0, 'center', 400)
  end
end

function UICosmetics.keypressed(key)
  if key == 'tab' then
    state.tab = (state.tab == "colors") and "shapes" or "colors"
    audio.play('ui_click')
  elseif key == 'up' then
    if state.tab == "colors" then
      state.colorSelection = math.max(1, state.colorSelection - 1)
      -- Auto-scroll up if selection goes above visible area
      if state.colorSelection < state.colorScroll + 1 then
        state.colorScroll = math.max(0, state.colorSelection - 1)
      end
    else
      state.shapeSelection = math.max(1, state.shapeSelection - 1)
      -- Auto-scroll up if selection goes above visible area
      if state.shapeSelection < state.shapeScroll + 1 then
        state.shapeScroll = math.max(0, state.shapeSelection - 1)
      end
    end
    audio.play('ui_click')
  elseif key == 'down' then
    if state.tab == "colors" then
      local colors = getColors()
      state.colorSelection = math.min(#colors, state.colorSelection + 1)
      -- Auto-scroll down if selection goes below visible area
      local layout = getLayout(love.graphics.getWidth(), love.graphics.getHeight())
      if state.colorSelection > state.colorScroll + layout.items.visibleCount then
        state.colorScroll = math.min(#colors - layout.items.visibleCount, state.colorSelection - layout.items.visibleCount)
      end
    else
      local shapes = getShapes()
      state.shapeSelection = math.min(#shapes, state.shapeSelection + 1)
      -- Auto-scroll down if selection goes below visible area
      local layout = getLayout(love.graphics.getWidth(), love.graphics.getHeight())
      if state.shapeSelection > state.shapeScroll + layout.items.visibleCount then
        state.shapeScroll = math.min(#shapes - layout.items.visibleCount, state.shapeSelection - layout.items.visibleCount)
      end
    end
    audio.play('ui_click')
  elseif key == 'escape' then
    audio.play('ui_click')
    return 'back'
  elseif key == 'return' or key == 'enter' or key == 'space' then
    audio.play('ui_click')
    if state.tab == "colors" then
      local colors = getColors()
      local color = colors[state.colorSelection]
      if Cosmetics.isColorUnlocked(color.id) then
        Cosmetics.selectColor(color.id)
        showMessage("Color equipped!")
      else
        local success, message = Cosmetics.purchaseColor(color.id)
        showMessage(message)
        if not success then
          audio.play('hit')
        end
      end
    else
      local shapes = getShapes()
      local shape = shapes[state.shapeSelection]
      if Cosmetics.isShapeUnlocked(shape.id) then
        Cosmetics.selectShape(shape.id)
        showMessage("Shape equipped!")
      else
        local success, message = Cosmetics.purchaseShape(shape.id)
        showMessage(message)
        if not success then
          audio.play('hit')
        end
      end
    end
  end
  return nil
end



function UICosmetics.pointerPressed(vw, vh, lx, ly)
  local layout = getLayout(vw, vh)
  
  -- Check tab buttons
  if lx >= layout.tabButtons.colors.x and lx <= layout.tabButtons.colors.x + layout.tabButtons.colors.w and
     ly >= layout.tabButtons.colors.y and ly <= layout.tabButtons.colors.y + layout.tabButtons.colors.h then
    state.tab = "colors"
    audio.play('ui_click')
    return nil
  end
  
  if lx >= layout.tabButtons.shapes.x and lx <= layout.tabButtons.shapes.x + layout.tabButtons.shapes.w and
     ly >= layout.tabButtons.shapes.y and ly <= layout.tabButtons.shapes.y + layout.tabButtons.shapes.h then
    state.tab = "shapes"
    audio.play('ui_click')
    return nil
  end
  
  -- Check back button
  if lx >= layout.back.x and lx <= layout.back.x + layout.back.w and
     ly >= layout.back.y and ly <= layout.back.y + layout.back.h then
    audio.play('ui_click')
    return 'back'
  end
  
  -- Don't check item clicks in pointerPressed - let pointerMoved handle tap vs drag
  -- This prevents accidental selections during swipe gestures
  
  -- Initialize touch scrolling for item list area
  if lx >= layout.items.x and lx <= layout.items.x + layout.items.width and
     ly >= layout.items.startY then
    touchStartY = ly
    touchStartTime = love.timer.getTime()
    isDragging = false  -- Don't start dragging immediately, wait for threshold
    scrollVelocity = 0
    currentScroll = state.tab == "colors" and state.colorScroll or state.shapeScroll
  end
  
  return nil
end

function UICosmetics.pointerMoved(vw, vh, lx, ly)
  -- Safety check for valid coordinates
  if not vw or not vh or not lx or not ly then
    return nil
  end
  
  if touchStartY then
    local deltaY = ly - touchStartY
    local dragThreshold = 10  -- Minimum movement to start scrolling
    
    -- Check if we've moved enough to start scrolling
    if not isDragging and math.abs(deltaY) > dragThreshold then
      isDragging = true
    end
    
    if isDragging then
      -- Apply boundaries
      local layout = getLayout(vw, vh)
      local colors = getColors()
      local shapes = getShapes()
      local maxColorScroll = math.max(0, #colors - layout.items.visibleCount)
      local maxShapeScroll = math.max(0, #shapes - layout.items.visibleCount)
      local totalItemHeight = layout.items.height + layout.items.spacing

      -- Update appropriate scroll based on current tab
      -- Dragging UP (negative deltaY) should increase scroll index (scroll down)
      -- Dragging DOWN (positive deltaY) should decrease scroll index (scroll up)
      local scrollDelta = -(deltaY / totalItemHeight)
      
      if state.tab == "colors" then
        state.colorScroll = state.colorScroll + scrollDelta
        state.colorScroll = math.max(0, math.min(maxColorScroll, state.colorScroll))
        currentScroll = state.colorScroll
      else
        state.shapeScroll = state.shapeScroll + scrollDelta
        state.shapeScroll = math.max(0, math.min(maxShapeScroll, state.shapeScroll))
        currentScroll = state.shapeScroll
      end
      
      touchStartY = ly
      scrollVelocity = deltaY
    end
  end
  return nil
end

function UICosmetics.pointerReleased(vw, vh, lx, ly)
  if touchStartY then
    local touchDuration = love.timer.getTime() - (touchStartTime or 0)
    local currentTime = love.timer.getTime()
    
    -- Safety check - ensure we have valid coordinates
    if not lx or not ly or not vw or not vh then
      touchStartY = nil
      touchStartTime = nil
      scrollVelocity = 0
      isDragging = false
      return nil
    end
    
    -- Check if this was a tap (not a drag)
    if not isDragging and touchDuration < 0.3 and touchDuration > 0.05 then
      -- Check for double tap
      local timeSinceLastTap = currentTime - lastTapTime
      local distanceFromLastTap = math.sqrt((lx - lastTapX)^2 + (ly - lastTapY)^2)
      
      local isDoubleTap = (timeSinceLastTap < doubleTapThreshold and distanceFromLastTap < doubleTapDistance)
      
      -- Update last tap info
      lastTapTime = currentTime
      lastTapX = lx
      lastTapY = ly
      
      if isDoubleTap then
        -- This was a double tap - handle purchase/equip
        local layout = getLayout(vw, vh)
        
        if state.tab == "colors" then
          local colors = getColors()
          local startIndex = math.max(1, state.colorScroll + 1)
          local endIndex = math.min(#colors, startIndex + layout.items.visibleCount - 1)
          
          for displayIndex = startIndex, endIndex do
            local actualIndex = displayIndex
            if actualIndex >= 1 and actualIndex <= #colors then
              local y = layout.items.startY + (displayIndex - startIndex) * (layout.items.height + layout.items.spacing)
              if lx >= layout.items.x and lx <= layout.items.x + layout.items.width and
                 ly >= y and ly <= y + layout.items.height then
                state.colorSelection = actualIndex
                audio.play('ui_click')
                
                local color = colors[actualIndex]
                if color and color.id then
                  if Cosmetics.isColorUnlocked(color.id) then
                    Cosmetics.selectColor(color.id)
                    showMessage("Color equipped!")
                  else
                    local success, message = Cosmetics.purchaseColor(color.id)
                    showMessage(message or "Purchase failed")
                    if not success then
                      audio.play('hit')
                    end
                  end
                end
                break
              end
            end
          end
        else -- shapes
          local shapes = getShapes()
          local startIndex = math.max(1, state.shapeScroll + 1)
          local endIndex = math.min(#shapes, startIndex + layout.items.visibleCount - 1)
          
          for displayIndex = startIndex, endIndex do
            local actualIndex = displayIndex
            if actualIndex >= 1 and actualIndex <= #shapes then
              local y = layout.items.startY + (displayIndex - startIndex) * (layout.items.height + layout.items.spacing)
              if lx >= layout.items.x and lx <= layout.items.x + layout.items.width and
                 ly >= y and ly <= y + layout.items.height then
                state.shapeSelection = actualIndex
                audio.play('ui_click')
                
                local shape = shapes[actualIndex]
                if shape and shape.id then
                  if Cosmetics.isShapeUnlocked(shape.id) then
                    Cosmetics.selectShape(shape.id)
                    showMessage("Shape equipped!")
                  else
                    local success, message = Cosmetics.purchaseShape(shape.id)
                    showMessage(message or "Purchase failed")
                    if not success then
                      audio.play('hit')
                    end
                  end
                end
                break
              end
            end
          end
        end
      else
        -- Single tap - just select the item, don't purchase
        local layout = getLayout(vw, vh)
        
        if state.tab == "colors" then
          local colors = getColors()
          if not colors or #colors == 0 then
            touchStartY = nil
            touchStartTime = nil
            scrollVelocity = 0
            isDragging = false
            return nil
          end
          
          local startIndex = math.max(1, state.colorScroll + 1)
          local endIndex = math.min(#colors, startIndex + layout.items.visibleCount - 1)
          
          for displayIndex = startIndex, endIndex do
            local actualIndex = displayIndex
            if actualIndex >= 1 and actualIndex <= #colors then
              local y = layout.items.startY + (displayIndex - startIndex) * (layout.items.height + layout.items.spacing)
              if lx >= layout.items.x and lx <= layout.items.x + layout.items.width and
                 ly >= y and ly <= y + layout.items.height then
                state.colorSelection = actualIndex
                audio.play('ui_click')
                showMessage("Double-tap to purchase/equip")
                break
              end
            end
          end
        else -- shapes
          local shapes = getShapes()
          if not shapes or #shapes == 0 then
            touchStartY = nil
            touchStartTime = nil
            scrollVelocity = 0
            isDragging = false
            return nil
          end
          
          local startIndex = math.max(1, state.shapeScroll + 1)
          local endIndex = math.min(#shapes, startIndex + layout.items.visibleCount - 1)
          
          for displayIndex = startIndex, endIndex do
            local actualIndex = displayIndex
            if actualIndex >= 1 and actualIndex <= #shapes then
              local y = layout.items.startY + (displayIndex - startIndex) * (layout.items.height + layout.items.spacing)
              if lx >= layout.items.x and lx <= layout.items.x + layout.items.width and
                 ly >= y and ly <= y + layout.items.height then
                state.shapeSelection = actualIndex
                audio.play('ui_click')
                showMessage("Double-tap to purchase/equip")
                break
              end
            end
          end
        end
      end
    elseif isDragging and touchDuration < 0.3 and math.abs(scrollVelocity) > 50 then
      -- Quick swipe - apply momentum with boundary checking
      local layout = getLayout(vw, vh)
      local colors = getColors()
      local shapes = getShapes()
      local maxColorScroll = math.max(0, #colors - layout.items.visibleCount)
      local maxShapeScroll = math.max(0, #shapes - layout.items.visibleCount)
      
      if state.tab == "colors" then
        local proposedScroll = state.colorScroll + scrollVelocity * 0.3
        state.colorScroll = math.max(0, math.min(maxColorScroll, proposedScroll))
      else
        local proposedScroll = state.shapeScroll + scrollVelocity * 0.3
        state.shapeScroll = math.max(0, math.min(maxShapeScroll, proposedScroll))
      end
    end
    
    -- Always apply boundaries (safety check)
    local layout = getLayout(vw, vh)
    local colors = getColors()
    local shapes = getShapes()
    local maxColorScroll = math.max(0, #colors - layout.items.visibleCount)
    local maxShapeScroll = math.max(0, #shapes - layout.items.visibleCount)
    
    state.colorScroll = math.max(0, math.min(maxColorScroll, state.colorScroll))
    state.shapeScroll = math.max(0, math.min(maxShapeScroll, state.shapeScroll))
  end
  
  touchStartY = nil
  touchStartTime = nil
  scrollVelocity = 0
  isDragging = false
  return nil
end

return UICosmetics
