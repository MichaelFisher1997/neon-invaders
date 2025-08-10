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
  -- Compute in virtual space using panel layout, then map to screen for hit testing
  local scale, ox, oy = scaling.getScale()
  local vw, vh = scaling.getVirtualSize()
  local leftPanel, centerPanel, rightPanel = scaling.getPanelsVirtual()
  -- Align touch zones with HUD control visuals (left: wide pad with divider, right: large fire circle)
  local gapL = math.floor(leftPanel.w * 0.06 + 0.5)
  local padH = math.floor(leftPanel.h * 0.22 + 0.5)
  local padW = leftPanel.w - gapL * 2
  local padX = leftPanel.x + gapL
  local padY = leftPanel.y + leftPanel.h - padH - gapL
  local halfW = padW / 2
  local leftBtn = { x = padX, y = padY, w = halfW, h = padH }
  local rightBtn = { x = padX + halfW, y = padY, w = halfW, h = padH }
  local gapR = math.floor(rightPanel.w * 0.06 + 0.5)
  local fireR = math.max(22, math.floor(rightPanel.w * 0.18 + 0.5))
  local fire = { x = rightPanel.x + rightPanel.w - fireR - gapR, y = rightPanel.y + rightPanel.h - fireR - gapR, r = fireR }

  -- Convert to screen-space for touch hit-testing
  local function toScreenRect(r)
    return { x = r.x * scale + ox, y = r.y * scale + oy, w = r.w * scale, h = r.h * scale }
  end
  local function toScreenCircle(c)
    return { x = c.x * scale + ox, y = c.y * scale + oy, r = c.r * scale }
  end
  return { left = toScreenRect(leftBtn), right = toScreenRect(rightBtn), fire = toScreenCircle(fire) }
end

local held = {
  left = false,
  right = false,
  fire = false,
}

local function pointInRect(px, py, r)
  return px >= r.x and px <= r.x + r.w and py >= r.y and py <= r.y + r.h
end

local function pointInCircle(px, py, c)
  local dx = px - c.x
  local dy = py - c.y
  return (dx * dx + dy * dy) <= (c.r * c.r)
end

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
    if pointInCircle(sx, sy, zones.fire) then held.fire = true end
  end

  if held.left then move = move - 1 end
  if held.right then move = move + 1 end
  state.moveAxis = clamp(move, -1, 1)

  state.fireHeld = love.keyboard.isDown("space") or held.fire
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
  love.graphics.setColor(1, 1, 1, 0.15)
  love.graphics.circle("fill", zones.fire.x, zones.fire.y, zones.fire.r)
end

function Input.getZones()
  return getTouchZones()
end

function Input.getHeld()
  -- Expose current held state for UI feedback
  return { left = held.left, right = held.right, fire = held.fire }
end

return Input
