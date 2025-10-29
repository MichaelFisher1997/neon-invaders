local Input = {}

local scaling = require("src.systems.scaling")

local state = {
  moveAxis = 0,
  fireHeld = false,
  firePressed = false,
  pausePressed = false,
  autoFire = true,
  swipeStart = nil,
  swipeDirection = nil,
}

local prev = {
  fireHeld = false,
  pauseHeld = false,
}

local held = { left = false, right = false, fire = false }
local touchHistory = {}

-- Helper functions
local function clamp(x, a, b) return math.max(a, math.min(b, x)) end

local function pointInRect(px, py, r)
  return px >= r.x and px <= r.x + r.w and py >= r.y and py <= r.y + r.h
end

local function getTouchZones()
  -- Entire side panels act as buttons: left = move left, right = move right
  local scale, ox, oy = scaling.getScale()
  local leftPanel, _, rightPanel = scaling.getPanelsVirtual()
  local leftRect = { x = leftPanel.x, y = leftPanel.y, w = leftPanel.w, h = leftPanel.h }
  local rightRect = { x = rightPanel.x, y = rightPanel.y, w = rightPanel.w, h = rightPanel.h }
  local function toScreenRect(r)
    return { x = r.x * scale + ox, y = r.y * scale + oy, w = r.w * scale, h = r.h * scale }
  end
  return { left = toScreenRect(leftRect), right = toScreenRect(rightRect) }
end

-- Unified pointer input handler for mouse and touch
local function handlePointerInput(x, y, isPressed, touchId)
  if not isPressed then
    held.left, held.right = false, false
    -- Clear swipe data on release
    if touchId and touchHistory[touchId] then
      touchHistory[touchId] = nil
    end
    return
  end
  
  -- Track touch for swipe detection
  if touchId then
    if not touchHistory[touchId] then
      touchHistory[touchId] = {x = x, y = y, time = love.timer.getTime()}
    else
      local touch = touchHistory[touchId]
      local dx = x - touch.x
      local dy = y - touch.y
      local dt = love.timer.getTime() - touch.time
      
      -- Detect swipe: minimum distance and time threshold
      if math.abs(dx) > 30 and dt < 0.3 then
        state.swipeDirection = dx > 0 and "right" or "left"
        state.swipeStart = {x = touch.x, y = touch.y}
      end
    end
  end
  
  local zones = getTouchZones()
  if pointInRect(x, y, zones.left) then held.left = true end
  if pointInRect(x, y, zones.right) then held.right = true end
end

-- Unified keyboard input handler
local function handleKeyboardInput()
  local left = love.keyboard.isDown("left") or love.keyboard.isDown("a")
  local right = love.keyboard.isDown("right") or love.keyboard.isDown("d")
  local move = 0
  if left then move = move - 1 end
  if right then move = move + 1 end
  return move
end

-- Update movement axis from all input sources
local function updateMovementAxis(keyboardMove)
  local move = keyboardMove
  if held.left then move = move - 1 end
  if held.right then move = move + 1 end
  state.moveAxis = clamp(move, -1, 1)
end

-- Main update function
function Input.update(dt)
  prev.fireHeld = state.fireHeld
  prev.pauseHeld = false -- pause is edge-only via keypressed

  -- Reset held state
  held.left, held.right, held.fire = false, false, false

  -- Handle keyboard input
  local keyboardMove = handleKeyboardInput()

  -- Handle touch input
  for _, id in ipairs(love.touch.getTouches()) do
    local sx, sy = love.touch.getPosition(id)
    handlePointerInput(sx, sy, true, id)
  end

  -- Handle mouse input (desktop testing)
  if love.mouse.isDown(1) then
    local mx, my = love.mouse.getPosition()
    handlePointerInput(mx, my, true, "mouse")
  end

  -- Update movement
  updateMovementAxis(keyboardMove)

  -- Auto-fire based on setting
  state.fireHeld = state.autoFire
  state.firePressed = (not prev.fireHeld) and state.fireHeld
  state.pausePressed = false
  
  -- Clear swipe direction after processing
  state.swipeDirection = nil
end

-- Handle key press events
function Input.keypressed(key)
  if key == "escape" then
    state.pausePressed = true
  elseif key == "f" then
    state.autoFire = not state.autoFire
  end
  -- fire edge is handled in update using previous state
end

function Input.get()
  return state
end

function Input.drawDebug()
  -- Visualize touch zones for debugging
  local zones = getTouchZones()
  love.graphics.setColor(0, 1, 0, 0.08)
  love.graphics.rectangle("fill", zones.left.x, zones.left.y, zones.left.w, zones.left.h)
  love.graphics.setColor(1, 0, 0, 0.08)
  love.graphics.rectangle("fill", zones.right.x, zones.right.y, zones.right.w, zones.right.h)
end

function Input.getZones()
  return getTouchZones()
end

function Input.getHeld()
  -- Expose current held state for UI feedback
  return { left = held.left, right = held.right, fire = held.fire }
end

--- Get swipe direction for mobile shooting
--- @return string|nil Swipe direction ("left" or "right") or nil
function Input.getSwipeDirection()
  return state.swipeDirection
end

--- Get swipe start position
--- @return table|nil Swipe start position {x, y} or nil
function Input.getSwipeStart()
  return state.swipeStart
end

--- Toggle auto-fire setting
--- @return boolean New auto-fire state
function Input.toggleAutoFire()
  state.autoFire = not state.autoFire
  return state.autoFire
end

--- Get auto-fire setting
--- @return boolean Current auto-fire state
function Input.getAutoFire()
  return state.autoFire
end

-- Unified UI input handler for pointer events (mouse/touch)
function Input.handleUIPointer(gameState, vw, vh, vx, vy, uiHandlers)
  -- Convert to virtual coordinates if needed
  local leftPanel, centerPanel = scaling.getPanelsVirtual()
  local lx = vx - centerPanel.x
  local ly = vy - centerPanel.y
  
  -- Check if pointer is in center panel for gameplay states
  local inCenterPanel = lx >= 0 and lx <= centerPanel.w and ly >= 0 and ly <= centerPanel.h
  
  -- Route to appropriate UI handler based on game state
  if gameState == "title" and uiHandlers.title then
    return uiHandlers.title.pointerPressed(vw, vh, vx, vy)
  elseif gameState == "gameover" and inCenterPanel and uiHandlers.gameover then
    return uiHandlers.gameover.pointerPressed(centerPanel.w, centerPanel.h, lx, ly)
  elseif gameState == "settings" and uiHandlers.settings then
    return uiHandlers.settings.pointerPressed(vw, vh, vx, vy)
  elseif gameState == "cosmetics" and uiHandlers.cosmetics then
    return uiHandlers.cosmetics.pointerPressed(vw, vh, vx, vy)
  elseif gameState == "play" and inCenterPanel and uiHandlers.upgrades then
    return uiHandlers.upgrades.pointerPressed(centerPanel.w, centerPanel.h, lx, ly)
  end
  
  return nil
end

-- Unified UI input handler for pointer movement
function Input.handleUIMove(gameState, vw, vh, vx, vy, uiHandlers)
  if gameState == "settings" and uiHandlers.settings then
    uiHandlers.settings.pointerMoved(vw, vh, vx, vy)
  elseif gameState == "cosmetics" and uiHandlers.cosmetics then
    uiHandlers.cosmetics.pointerMoved(vw, vh, vx, vy)
  end
end

-- Unified UI input handler for pointer release
function Input.handleUIRelease(gameState, vw, vh, vx, vy, uiHandlers)
  if gameState == "settings" and uiHandlers.settings then
    uiHandlers.settings.pointerReleased()
  elseif gameState == "cosmetics" and uiHandlers.cosmetics then
    uiHandlers.cosmetics.pointerReleased(vw, vh, vx, vy)
  end
end

return Input
