local Cosmetics = require("src.systems.cosmetics")
local Economy = require("src.systems.economy")
local Constants = require("src.config.constants")
local audio = require("src.audio.audio")
local Fonts = require("src.ui.fonts")
local InputMode = require("src.core.inputmode")

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
  for id, color in pairs(Constants.ECONOMY.cosmetics.colors) do
    color.id = id
    table.insert(colors, color)
  end
  return colors
end

local function getShapes()
  local shapes = {}
  for id, shape in pairs(Constants.ECONOMY.cosmetics.shapes) do
    shape.id = id
    table.insert(shapes, shape)
  end
  return shapes
end

local function getLayout(vw, vh)
  local tabButtonsY = 110
  local tabButtonW = 120
  local tabButtonH = 40
  local colorsTabX = vw/2 - tabButtonW - 10
  local shapesTabX = vw/2 + 10
  
  local itemStartY = 170
  local itemHeight = 80
  local itemSpacing = 10
  local itemWidth = math.min(450, vw * 0.8)
  local itemX = (vw - itemWidth) / 2
  
  -- Show only 5 items at once
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
  local isSelectedColor = Cosmetics.getSelectedColor() == item.id
  
  -- Background
  if isSelected then
    love.graphics.setColor(0.3, 0.5, 0.9, 0.8)
  else
    love.graphics.setColor(0.1, 0.2, 0.4, 0.6)
  end
  love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 8, 8)
  
  -- Border
  love.graphics.setColor(0.5, 0.7, 1.0, 1.0)
  love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 8, 8)
  
  -- Color preview
  local previewColor
  if item.id == 'rgb_trip' then
    previewColor = rgbTripColor(love.timer.getTime())
  else
    previewColor = item.color or {1,1,1,1}
  end
  love.graphics.setColor(previewColor)
  love.graphics.circle("fill", rect.x + 30, rect.y + rect.h/2, 20)
  
  -- Text
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Fonts.get(20))
  love.graphics.print(item.name, rect.x + 70, rect.y + 10)
  
  love.graphics.setFont(Fonts.get(16))
  love.graphics.setColor(0.8, 0.8, 0.8, 1)
  love.graphics.print(item.description, rect.x + 70, rect.y + 35)
  
  -- Status
  if isUnlocked then
    if isSelectedColor then
      love.graphics.setColor(0.5, 1.0, 0.5, 1)
      love.graphics.printf("EQUIPPED", 0, rect.y + 15, rect.x + rect.w - 10, "right")
    else
      love.graphics.setColor(0.8, 0.8, 0.8, 1)
      love.graphics.printf("OWNED", 0, rect.y + 15, rect.x + rect.w - 10, "right")
    end
  else
    love.graphics.setColor(1.0, 1.0, 0.5, 1)
    love.graphics.printf(item.cost .. " credits", 0, rect.y + 15, rect.x + rect.w - 10, "right")
  end
end

local function drawShapeItem(layout, item, index, isSelected, displayIndex)
  local y = layout.items.startY + (displayIndex - 1) * (layout.items.height + layout.items.spacing)
  local rect = { x = layout.items.x, y = y, w = layout.items.width, h = layout.items.height }
  
  local isUnlocked = Cosmetics.isShapeUnlocked(item.id)
  local isSelectedShape = Cosmetics.getSelectedShape() == item.id
  
  -- Background
  if isSelected then
    love.graphics.setColor(0.3, 0.5, 0.9, 0.8)
  else
    love.graphics.setColor(0.1, 0.2, 0.4, 0.6)
  end
  love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 8, 8)
  
  -- Border
  love.graphics.setColor(0.5, 0.7, 1.0, 1.0)
  love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 8, 8)
  
  -- Shape preview (use player proportions for preview consistency)
  love.graphics.setColor(Cosmetics.getColor())
  local previewWidth = Constants.PLAYER.width * 2.5
  local previewHeight = Constants.PLAYER.height * 2.5
  Cosmetics.drawSpecificShape(item.id, rect.x + 30, rect.y + rect.h/2, previewWidth, previewHeight)
  
  -- Text
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Fonts.get(20))
  love.graphics.print(item.name, rect.x + 130, rect.y + 12)
  
  love.graphics.setFont(Fonts.get(16))
  love.graphics.setColor(0.8, 0.8, 0.8, 1)
  love.graphics.print(item.description, rect.x + 130, rect.y + 35)
  
  -- Status
  if isUnlocked then
    if isSelectedShape then
      love.graphics.setColor(0.5, 1.0, 0.5, 1)
      love.graphics.printf("EQUIPPED", 0, rect.y + 20, rect.x + rect.w - 15, "right")
    else
      love.graphics.setColor(0.8, 0.8, 0.8, 1)
      love.graphics.printf("OWNED", 0, rect.y + 20, rect.x + rect.w - 15, "right")
    end
  else
    love.graphics.setColor(1.0, 1.0, 0.5, 1)
    love.graphics.printf(item.cost .. " credits", 0, rect.y + 20, rect.x + rect.w - 15, "right")
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
  
  -- Title
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Fonts.get(40))
  love.graphics.printf("Cosmetics Shop", 0, 20, vw, "center")
  
  -- Credits display
  love.graphics.setFont(Fonts.get(22))
  love.graphics.printf("Credits: " .. Economy.getCredits(), 0, 70, vw, "center")
  
  -- Tab buttons
  local colorsTab = layout.tabButtons.colors
  local shapesTab = layout.tabButtons.shapes
  
  -- Colors tab
  if state.tab == "colors" then
    love.graphics.setColor(0.3, 0.5, 0.9, 0.9)
  else
    love.graphics.setColor(0.2, 0.4, 0.8, 0.7)
  end
  love.graphics.rectangle("fill", colorsTab.x, colorsTab.y, colorsTab.w, colorsTab.h, 6, 6)
  love.graphics.setColor(0.5, 0.7, 1.0, 1.0)
  love.graphics.rectangle("line", colorsTab.x, colorsTab.y, colorsTab.w, colorsTab.h, 6, 6)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Fonts.get(20))
  love.graphics.printf("Colors", colorsTab.x, colorsTab.y + 10, colorsTab.w, "center")
  
  -- Shapes tab
  if state.tab == "shapes" then
    love.graphics.setColor(0.3, 0.5, 0.9, 0.9)
  else
    love.graphics.setColor(0.2, 0.4, 0.8, 0.7)
  end
  love.graphics.rectangle("fill", shapesTab.x, shapesTab.y, shapesTab.w, shapesTab.h, 6, 6)
  love.graphics.setColor(0.5, 0.7, 1.0, 1.0)
  love.graphics.rectangle("line", shapesTab.x, shapesTab.y, shapesTab.w, shapesTab.h, 6, 6)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Fonts.get(20))
  love.graphics.printf("Shapes", shapesTab.x, shapesTab.y + 10, shapesTab.w, "center")
  
  -- Draw items based on current tab (with scrolling)
  if state.tab == "colors" then
    local colors = getColors()
    local startIndex = state.colorScroll + 1
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
    local startIndex = state.shapeScroll + 1
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
  
  -- Back button
  local back = layout.back
  love.graphics.setColor(0.2, 0.4, 0.8, 0.8)
  love.graphics.rectangle("fill", back.x, back.y, back.w, back.h, 6, 6)
  love.graphics.setColor(0.5, 0.7, 1.0, 1.0)
  love.graphics.rectangle("line", back.x, back.y, back.w, back.h, 6, 6)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Fonts.get(18))
  love.graphics.printf("Back", back.x, back.y + 10, back.w, "center")
  
  -- Instructions
  love.graphics.setFont(Fonts.get(14))
  love.graphics.setColor(0.7, 0.7, 0.7, 1)
  love.graphics.setFont(Fonts.get(14))
  love.graphics.setColor(0.7, 0.7, 0.7, 1)
  local y = vh - 30
  local font = Fonts.get(14)
  local useText = "Use UP/DOWN "
  local restText = " arrows to select, ENTER to purchase/equip, TAB to switch tabs, ESC to go back"
  local useWidth = font:getWidth(useText)
  local restWidth = font:getWidth(restText)
  local arrowWidth = 20
  local totalWidth = useWidth + arrowWidth + restWidth
  local startX = (vw - totalWidth) / 2
  love.graphics.print(useText, startX, y)
  local arrowX = startX + useWidth
  -- Up arrow (solid)
  love.graphics.polygon("fill", arrowX + 3, y + 12, arrowX + 8, y + 12, arrowX + 5.5, y + 6)
  -- Down arrow (solid)
  love.graphics.polygon("fill", arrowX + 3, y + 8, arrowX + 8, y + 8, arrowX + 5.5, y + 14)
  if restText then
    love.graphics.print(restText, arrowX + arrowWidth, y)
  end

  
  -- Message display
  if state.messageTimer > 0 then
    local alpha = math.min(1.0, state.messageTimer)
    love.graphics.setColor(1.0, 1.0, 0.5, alpha)
  love.graphics.setFont(Fonts.get(20))
    love.graphics.printf(state.message, 0, vh/2 - 20, vw, "center")
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
  
  -- Check item clicks
  if state.tab == "colors" then
    local colors = getColors()
    local startIndex = state.colorScroll + 1
    local endIndex = math.min(startIndex + layout.items.visibleCount - 1, #colors)
    
    for displayIndex = startIndex, endIndex do
      local actualIndex = displayIndex
      local y = layout.items.startY + (displayIndex - startIndex) * (layout.items.height + layout.items.spacing)
      if lx >= layout.items.x and lx <= layout.items.x + layout.items.width and
         ly >= y and ly <= y + layout.items.height then
        state.colorSelection = actualIndex
        audio.play('ui_click')
        
        local color = colors[actualIndex]
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
        break
      end
    end
  else
    local shapes = getShapes()
    local startIndex = state.shapeScroll + 1
    local endIndex = math.min(startIndex + layout.items.visibleCount - 1, #shapes)
    
    for displayIndex = startIndex, endIndex do
      local actualIndex = displayIndex
      local y = layout.items.startY + (displayIndex - startIndex) * (layout.items.height + layout.items.spacing)
      if lx >= layout.items.x and lx <= layout.items.x + layout.items.width and
         ly >= y and ly <= y + layout.items.height then
        state.shapeSelection = actualIndex
        audio.play('ui_click')
        
        local shape = shapes[actualIndex]
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
        break
      end
    end
  end
  
  -- Initialize touch scrolling for item list area
  if lx >= layout.items.x and lx <= layout.items.x + layout.items.width and
     ly >= layout.items.startY then
    touchStartY = ly
    touchStartTime = love.timer.getTime()
    isDragging = true
    scrollVelocity = 0
    currentScroll = state.tab == "colors" and state.colorScroll or state.shapeScroll
  end
  
  return nil
end

function UICosmetics.pointerMoved(vw, vh, lx, ly)
  if touchStartY and isDragging then
    local deltaY = ly - touchStartY
    
    -- Update appropriate scroll based on current tab
    if state.tab == "colors" then
      state.colorScroll = state.colorScroll + deltaY
      currentScroll = state.colorScroll
    else
      state.shapeScroll = state.shapeScroll + deltaY
      currentScroll = state.shapeScroll
    end
    
    -- Apply boundaries
    local layout = getLayout(vw, vh)
    local maxScroll = 0
    local items = state.tab == "colors" and getColors() or getShapes()
    local maxScrollOffset = math.max(0, #items - layout.items.visibleCount)
    
    if state.tab == "colors" then
      state.colorScroll = math.max(0, math.min(maxScrollOffset, state.colorScroll))
    else
      state.shapeScroll = math.max(0, math.min(maxScrollOffset, state.shapeScroll))
    end
    
    touchStartY = ly
    scrollVelocity = deltaY
  end
  return nil
end

function UICosmetics.pointerReleased(vw, vh, lx, ly)
  if touchStartY then
    local touchDuration = love.timer.getTime() - (touchStartTime or 0)
    if touchDuration < 0.3 and math.abs(scrollVelocity) > 50 then
      -- Quick swipe - apply momentum
      if state.tab == "colors" then
        state.colorScroll = state.colorScroll + scrollVelocity * 0.3
      else
        state.shapeScroll = state.shapeScroll + scrollVelocity * 0.3
      end
    end
    
    -- Apply boundaries
    local layout = getLayout(vw, vh)
    local maxScroll = 0
    local items = state.tab == "colors" and getColors() or getShapes()
    local maxScrollOffset = math.max(0, #items - layout.items.visibleCount)
    
    state.colorScroll = math.max(0, math.min(maxScrollOffset, state.colorScroll))
    state.shapeScroll = math.max(0, math.min(maxScrollOffset, state.shapeScroll))
  end
  
  touchStartY = nil
  touchStartTime = nil
  scrollVelocity = 0
  isDragging = false
  return nil
end

return UICosmetics
