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
  
  local currentStep = TUTORIAL_STEPS[state.step]
  if not currentStep then
    return
  end
  
  -- Draw semi-transparent background
  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.rectangle("fill", 0, 0, vw, vh)
  
  -- Draw tutorial box
  local boxWidth = 400
  local boxHeight = 150
  local boxX = (vw - boxWidth) / 2
  local boxY = (vh - boxHeight) / 2
  
  love.graphics.setColor(Constants.COLORS.cyan[1], Constants.COLORS.cyan[2], Constants.COLORS.cyan[3], 0.2)
  love.graphics.rectangle("fill", boxX - 4, boxY - 4, boxWidth + 8, boxHeight + 8)
  
  love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
  love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight)
  
  love.graphics.setColor(Constants.COLORS.cyan)
  love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight)
  
  -- Draw text
  love.graphics.setColor(Constants.COLORS.white)
  love.graphics.printf(currentStep.title, boxX + 20, boxY + 20, boxWidth - 40, "center")
  
  love.graphics.setColor(0.8, 0.8, 0.8)
  love.graphics.printf(currentStep.text, boxX + 20, boxY + 60, boxWidth - 40, "center")
  
  -- Draw progress indicator
  local progressWidth = (boxWidth - 40) * (state.timer / currentStep.duration)
  love.graphics.setColor(Constants.COLORS.magenta)
  love.graphics.rectangle("fill", boxX + 20, boxY + boxHeight - 10, progressWidth, 4)
  
  -- Draw step counter
  love.graphics.setColor(Constants.COLORS.white)
  love.graphics.printf(string.format("Step %d/%d", state.step, #TUTORIAL_STEPS), 
                      boxX + 20, boxY + boxHeight - 30, boxWidth - 40, "center")
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