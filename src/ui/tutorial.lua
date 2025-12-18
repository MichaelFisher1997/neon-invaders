local Tutorial = {}

local Constants = require("src.config.constants")

local state = {
  active = false,
  step = 1,
  timer = 0,
  completed = false,
}

local TUTORIAL_STEPS = {
  {
    title = "Welcome to Neon Invaders!",
    text = "Move your ship with Arrow Keys or A/D\nTouch the side panels on mobile",
    duration = 4.0,
    position = "center"
  },
  {
    title = "Shooting",
    text = "Your ship auto-fires by default\nPress F to toggle auto-fire\nOn mobile, swipe to shoot in a direction",
    duration = 4.0,
    position = "center"
  },
  {
    title = "Objective",
    text = "Destroy all alien waves\nCollect power-ups for advantages\nSurvive as long as possible!",
    duration = 3.5,
    position = "center"
  },
  {
    title = "Good Luck!",
    text = "Press ESC to pause anytime\nPress any key to start playing",
    duration = 3.0,
    position = "center"
  }
}

--- Start tutorial sequence
function Tutorial.start()
  if Tutorial.isCompleted() then
    return
  end
  
  state.active = true
  state.step = 1
  state.timer = 0
end

--- Update tutorial state
--- @param dt number Delta time
function Tutorial.update(dt)
  if not state.active then
    return
  end
  
  state.timer = state.timer + dt
  
  local currentStep = TUTORIAL_STEPS[state.step]
  if state.timer >= currentStep.duration then
    state.step = state.step + 1
    state.timer = 0
    
    if state.step > #TUTORIAL_STEPS then
      Tutorial.complete()
    end
  end
end

--- Draw tutorial overlay
--- @param vw number Virtual width
--- @param vh number Virtual height
function Tutorial.draw(vw, vh)
  if not state.active then
    return
  end
  
  -- Safety checks
  if not vw or not vh or vw <= 0 or vh <= 0 then
    return
  end
  
  local currentStep = TUTORIAL_STEPS[state.step]
  if not currentStep or not currentStep.title or not currentStep.text then
    return
  end
  
  -- Draw semi-transparent background
  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.rectangle("fill", 0, 0, vw, vh)
  
  -- Draw tutorial box (responsive sizing for mobile)
  local InputMode = require("src.core.inputmode")
  local isMobile = InputMode.isTouchMode()
  
  -- For mobile, use smaller dimensions and ensure proper centering
  local boxWidth = isMobile and math.min(350, vw * 0.7) or math.min(400, vw * 0.8)
  local boxHeight = isMobile and math.min(120, vh * 0.25) or math.min(150, vh * 0.3)
  local boxX = (vw - boxWidth) / 2
  local boxY = (vh - boxHeight) / 2
  
 -- Safe color access
  local cyanColor = (Constants.COLORS and Constants.COLORS.cyan) or {0.153, 0.953, 1.0, 1.0}
  love.graphics.setColor(cyanColor[1], cyanColor[2], cyanColor[3], 0.2)
  love.graphics.rectangle("fill", boxX - 4, boxY - 4, boxWidth + 8, boxHeight + 8)
  
  love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
  love.graphics.rectangle("fill", boxX, boxY, boxHeight)
  
  love.graphics.setColor(cyanColor)
  love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight)
  
  -- Draw text (responsive font sizes and padding)
  local Fonts = require("src.ui.fonts")
  local titleFont = isMobile and (Fonts.get(24) or love.graphics.newFont(24)) or (Fonts.get(28) or love.graphics.newFont(28))
  local textFont = isMobile and (Fonts.get(14) or love.graphics.newFont(14)) or (Fonts.get(16) or love.graphics.newFont(16))
  local padding = isMobile and 15 or 20
  
  -- Safe color access
  local whiteColor = (Constants.COLORS and Constants.COLORS.white) or {1, 1, 1, 1}
  love.graphics.setColor(whiteColor)
  love.graphics.setFont(titleFont)
  love.graphics.printf(currentStep.title, boxX + padding, boxY + padding, boxWidth - padding * 2, "center")
  
  love.graphics.setColor(0.8, 0.8, 0.8)
  love.graphics.setFont(textFont)
  love.graphics.printf(currentStep.text, boxX + padding, boxY + padding + (isMobile and 35 or 40), boxWidth - padding * 2, "center")
  
  -- Draw progress indicator (responsive)
  local progressWidth = (boxWidth - padding * 2) * (state.timer / currentStep.duration)
  local magentaColor = (Constants.COLORS and Constants.COLORS.magenta) or {1.0, 0.182, 0.651, 1.0}
  love.graphics.setColor(magentaColor)
  love.graphics.rectangle("fill", boxX + padding, boxY + boxHeight - (isMobile and 8 or 10), progressWidth, isMobile and 3 or 4)
  
  -- Draw step counter (responsive)
  love.graphics.setColor(whiteColor)
  love.graphics.setFont(isMobile and (Fonts.get(12) or love.graphics.newFont(12)) or (Fonts.get(14) or love.graphics.newFont(14)))
  love.graphics.printf(string.format("Step %d/%d", state.step, #TUTORIAL_STEPS), 
                      boxX + padding, boxY + boxHeight - (isMobile and 25 or 30), boxWidth - padding * 2, "center")
end

--- Skip tutorial
function Tutorial.skip()
  Tutorial.complete()
end

--- Complete tutorial
function Tutorial.complete()
  state.active = false
  state.completed = true
  
  -- Save completion state
  local Save = require("src.systems.save")
  local saveData = Save.loadLua("save.dat", {}) or {}
  saveData.tutorialCompleted = true
  Save.saveLua("save.dat", saveData)
end

--- Check if tutorial is completed
--- @return boolean True if tutorial was completed
function Tutorial.isCompleted()
  if state.completed then
    return true
  end
  
  -- Check save data
  local Save = require("src.systems.save")
  local saveData = Save.loadLua("save.dat", {}) or {}
  return saveData.tutorialCompleted == true
end

--- Check if tutorial is currently active
--- @return boolean True if tutorial is running
function Tutorial.isActive()
  return state.active
end

--- Handle key press during tutorial
--- @param key string The key that was pressed
function Tutorial.keypressed(key)
  if not state.active then
    return
  end
  
  -- Allow skipping with any key except escape
  if key ~= "escape" then
    Tutorial.skip()
  end
end

return Tutorial