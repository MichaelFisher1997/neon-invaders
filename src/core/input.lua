local Input = {}

local scaling = require("src.systems.scaling")

local state = {
  moveAxis = 0,
  fireHeld = false,
  firePressed = false,
  pausePressed = false,
}

local prev = {
  fireHeld = false,
  pauseHeld = false,
}

local function clamp(x, a, b) return math.max(a, math.min(b, x)) end

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

local held = { left = false, right = false, fire = false }

local function pointInRect(px, py, r)
  return px >= r.x and px <= r.x + r.w and py >= r.y and py <= r.y + r.h
end

-- no circle needed anymore

function Input.update(dt)
  prev.fireHeld = state.fireHeld
  prev.pauseHeld = false -- pause is edge-only via keypressed

  -- Keyboard
  local left = love.keyboard.isDown("left") or love.keyboard.isDown("a")
  local right = love.keyboard.isDown("right") or love.keyboard.isDown("d")
  local move = 0
  if left then move = move - 1 end
  if right then move = move + 1 end

  -- Touch
  held.left, held.right, held.fire = false, false, false
  for _, id in ipairs(love.touch.getTouches()) do
    local sx, sy = love.touch.getPosition(id)
    local zones = getTouchZones()
    if pointInRect(sx, sy, zones.left) then held.left = true end
    if pointInRect(sx, sy, zones.right) then held.right = true end
  end

  -- Mouse (desktop testing): treat left click like a touch
  if love.mouse.isDown(1) then
    local mx, my = love.mouse.getPosition()
    local zones = getTouchZones()
    if pointInRect(mx, my, zones.left) then held.left = true end
    if pointInRect(mx, my, zones.right) then held.right = true end
  end

  if held.left then move = move - 1 end
  if held.right then move = move + 1 end
  state.moveAxis = clamp(move, -1, 1)

  -- Auto-fire always on
  state.fireHeld = true
  state.firePressed = (not prev.fireHeld) and state.fireHeld
  -- pausePressed handled in keypressed
  state.pausePressed = false
end

function Input.keypressed(key)
  if key == "escape" then
    state.pausePressed = true
  end
  if key == "space" then
    -- fire edge is handled in update using previous state
  end
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

return Input
