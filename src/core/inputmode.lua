local InputMode = {}

local mode = "touch" -- Default to touch for mobile
local hasKeyboard = false
local hasTouch = false

function InputMode.init()
  -- Check for touch capabilities
  hasTouch = love.touch and love.touch.getTouches() ~= nil
  
  -- Check for keyboard (this will be updated on first keypress)
  hasKeyboard = false
  mode = hasTouch and "touch" or "keyboard"
end

function InputMode.onKeyPressed()
  if not hasKeyboard then
    hasKeyboard = true
    -- Switch to keyboard mode if we detect keyboard input
    mode = "keyboard"
  end
end

function InputMode.onTouchPressed()
  if not hasTouch then
    hasTouch = true
  end
  -- Only switch to touch mode if we haven't detected keyboard yet
  if not hasKeyboard then
    mode = "touch"
  end
end

function InputMode.getMode()
  return mode
end

function InputMode.isTouchMode()
  return mode == "touch"
end

function InputMode.isKeyboardMode()
  return mode == "keyboard"
end

function InputMode.hasKeyboard()
  return hasKeyboard
end

function InputMode.hasTouch()
  return hasTouch
end

function InputMode.reset()
  hasKeyboard = false
  hasTouch = false
  mode = "touch"
end

return InputMode