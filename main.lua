-- Service container for dependency injection
local services = {
  scaling = require("src.systems.scaling"),
  starfield = require("src.fx.starfield"),
  input = require("src.core.input"),
  inputMode = require("src.core.inputmode"),
  state = require("src.core.state"),
  game = require("src.game.game"),
  hud = require("src.ui.hud"),
  title = require("src.ui.title"),
  pauseUI = require("src.ui.pause"),
  gameoverUI = require("src.ui.gameover"),
  screenshake = require("src.fx.screenshake"),
  settingsUI = require("src.ui.settings"),
  cosmeticsUI = require("src.ui.cosmetics"),
  settings = require("src.systems.settings"),
  audio = require("src.audio.audio"),
  tutorial = require("src.ui.tutorial"),
  economy = require("src.systems.economy"),
  upgradeMenu = require("src.ui.upgrademenu"),
  bossGallery = require("src.ui.bossgallery"),
  events = require("src.game.events"),
  Constants = require("src.config.constants"),
}

local SHOW_DEBUG_TOUCH = false
local SHOW_DEBUG_OVERLAY = false
local COLORS = services.Constants.COLORS

-- UI handlers for unified input processing
local uiHandlers = {
  title = services.title,
  gameover = services.gameoverUI,
  settings = services.settingsUI,
  cosmetics = services.cosmeticsUI,
  upgradeMenu = services.upgradeMenu,
  bossGallery = services.bossGallery,
  pause = services.pauseUI,
}

function love.load()
  services.scaling.setup()
  local vw, vh = services.scaling.getVirtualSize()
  services.starfield.init(vw, vh)
  love.window.setTitle("Neon Invaders")
  services.inputMode.init()
  services.state.set("title")
  services.title.enter()
  services.audio.load()
  services.audio.setMusic(services.audio.music)
  
  -- Initialize economy system
  services.economy.init()
  
  -- Check if tutorial should be shown
  if not services.tutorial.isCompleted() then
    services.tutorial.start()
  end
end

function love.resize(w, h)
  services.scaling.resize(w, h)
end

function love.keypressed(key)
  services.inputMode.onKeyPressed()
  services.input.keypressed(key)
  services.tutorial.keypressed(key)
  if key == "f1" then SHOW_DEBUG_TOUCH = not SHOW_DEBUG_TOUCH end
  if key == "f2" then SHOW_DEBUG_OVERLAY = not SHOW_DEBUG_OVERLAY end
  
  local curState = services.state.get()
  if curState == "title" then
    services.title.keypressed(key)
    if key == "space" or key == "return" or key == "enter" then
      local sel = services.title.getSelected()
      handleUIAction(sel, curState)
    end
  elseif curState == "play" then
    if key == "escape" then
      services.state.set("pause")
    end
  elseif curState == "pause" then
    if key == "escape" then services.state.set("play") end
    if key == "r" then local vw, vh = services.scaling.getVirtualSize(); services.game.init(vw, vh); services.state.set("play") end
    if key == "q" then services.state.set("title"); services.title.enter() end
  elseif curState == "gameover" then
    local action = services.gameoverUI.keypressed(key)
    handleUIAction(action, curState)
  elseif curState == "settings" then
    services.settingsUI.keypressed(key)
    if (key == "return" or key == "enter") and not services.settingsUI.isConfirmationActive() then 
      services.settings.save(); services.state.set("title"); services.title.enter() 
    end
  elseif curState == "cosmetics" then
    local action = services.cosmeticsUI.keypressed(key)
    handleUIAction(action, curState)
  elseif curState == "upgradeMenu" then
    services.upgradeMenu.keypressed(key)
  elseif curState == "bossGallery" then
    local action = services.bossGallery.keypressed(key)
    handleUIAction(action, curState)
  end
end

-- Helper function to handle UI actions
function handleUIAction(action, curState)
  if not action then return end
  
  if curState == "title" then
    if action == "Start" then
      local gw, gh = services.scaling.getVirtualSize()
      services.game.init(gw, gh)
      services.state.set("play")
    elseif action == "Upgrades" then
      services.state.set("upgradeMenu")
      services.upgradeMenu.init()
      services.inputMode.setTouchDelay() -- Prevent accidental touches
    elseif action == "Boss Gallery" then
      services.bossGallery.enter()
      services.state.setWithDelay("bossGallery")
      services.inputMode.setTouchDelay() -- Prevent accidental touches
    elseif action == "Cosmetics" then
      services.cosmeticsUI.enter()
      services.state.setWithDelay("cosmetics")
      services.inputMode.setTouchDelay() -- Prevent accidental touches
    elseif action == "Settings" then
      services.settingsUI.enter()
      services.state.setWithDelay("settings")
      services.inputMode.setTouchDelay() -- Prevent accidental touches
    elseif action == "Quit" then
      love.event.quit()
    end
  elseif curState == "gameover" then
    if action == 'retry' then
      local vw, vh = services.scaling.getVirtualSize()
      services.game.init(vw, vh)
      services.state.set("play")
    elseif action == 'menu' then
      services.state.set("title")
      services.title.enter()
    elseif action == 'quit' then
      love.event.quit()
    end
  elseif curState == "settings" then
    if action == 'back' then
      services.settings.save()
      services.state.set("title")
      services.title.enter()
      services.inputMode.setTouchDelay() -- Prevent accidental touches
    end
  elseif curState == "cosmetics" then
    if action == 'back' then
      services.state.set("title")
      services.title.enter()
      services.inputMode.setTouchDelay() -- Prevent accidental touches
    end
  elseif curState == "bossGallery" then
    if action == 'title' then
      services.state.set("title")
      services.title.enter()
      services.inputMode.setTouchDelay() -- Prevent accidental touches
    end
  elseif curState == "pause" then
    if action == 'resume' then
      services.state.set("play")
    elseif action == 'restart' then
      local vw, vh = services.scaling.getVirtualSize()
      services.game.init(vw, vh)
      services.state.set("play")
    elseif action == 'quit' then
      services.state.set("title")
      services.title.enter()
      services.inputMode.setTouchDelay() -- Prevent accidental touches
    end
  end
end

-- Unified mouse/touch handlers using input system
function love.mousepressed(x, y, button)
  local vx, vy = services.scaling.toVirtual(x, y)
  local vw, vh = services.scaling.getVirtualSize()
  local curState = services.state.get()
  
  -- Handle UI input
  local result = services.input.handleUIPointer(curState, vw, vh, vx, vy, uiHandlers)
  handleUIAction(result, curState)
end

function love.mousemoved(x, y, dx, dy, istouch)
  local vx, vy = services.scaling.toVirtual(x, y)
  local vw, vh = services.scaling.getVirtualSize()
  services.input.handleUIMove(services.state.get(), vw, vh, vx, vy, uiHandlers)
end

function love.mousereleased(x, y, button)
  local vx, vy = services.scaling.toVirtual(x, y)
  local vw, vh = services.scaling.getVirtualSize()
  services.input.handleUIRelease(services.state.get(), vw, vh, vx, vy, uiHandlers)
end

function love.touchpressed(id, x, y, dx, dy, pressure)
  services.inputMode.onTouchPressed()
  
  local vx, vy = services.scaling.toVirtual(x, y)
  local vw, vh = services.scaling.getVirtualSize()
  local curState = services.state.get()
  
  -- Allow scrolling in boss gallery and cosmetics even during touch delay
  -- But keep protection for upgrades menu to prevent accidental purchases
  if curState == "bossGallery" or curState == "cosmetics" then
    -- Always allow touch input for scrolling menus (scrolling should work immediately)
    local result = services.input.handleUIPointer(curState, vw, vh, vx, vy, uiHandlers)
    handleUIAction(result, curState)
  else
    -- Check if touch is delayed for other menus (prevent accidental touches after screen transitions)
    if services.inputMode.isTouchDelayed() then
      return
    end
    
    -- Handle UI input
    local result = services.input.handleUIPointer(curState, vw, vh, vx, vy, uiHandlers)
    handleUIAction(result, curState)
  end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
  local vx, vy = services.scaling.toVirtual(x, y)
  local vw, vh = services.scaling.getVirtualSize()
  services.input.handleUIMove(services.state.get(), vw, vh, vx, vy, uiHandlers)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
  local vx, vy = services.scaling.toVirtual(x, y)
  local vw, vh = services.scaling.getVirtualSize()
  services.input.handleUIRelease(services.state.get(), vw, vh, vx, vy, uiHandlers)
end

function love.update(dt)
  services.scaling.update()
  services.input.update(dt)
  services.starfield.update(dt)
  services.screenshake.update(dt)
  services.audio.update()
  services.tutorial.update(dt)
  services.inputMode.update(dt)
  services.state.update(dt)
  
  local cur = services.state.get()
  if cur == "title" then
    services.title.update(dt)
  elseif cur == "upgradeMenu" then
    services.upgradeMenu.update(dt)
  elseif cur == "settings" then
    services.settingsUI.update(dt)
  elseif cur == "cosmetics" then
     services.cosmeticsUI.update(dt)
  elseif cur == "bossGallery" then
     services.bossGallery.update(dt)
  elseif cur == "play" then
    services.game.update(dt, services.input.get())
    if services.game.isOver() then services.gameoverUI.enter(); services.state.set("gameover") end
  elseif services.state.get() == "pause" then
    -- paused, no game update
  elseif services.state.get() == "gameover" then
    -- awaiting input
  end
end

function love.draw()
  services.scaling.begin()

  local vw, vh = services.scaling.getVirtualSize()
  local leftPanel, centerPanel, rightPanel = services.scaling.getPanelsVirtual()
  local cur = services.state.get()

  -- Draw background only in center viewport to avoid space behind controls
  services.scaling.pushViewport(centerPanel)
  services.starfield.draw()
  services.scaling.popViewport()

  if cur == "title" then
    services.title.draw(vw, vh)
  elseif cur == "upgradeMenu" then
    services.upgradeMenu.draw()
  elseif cur == "settings" then
    services.settingsUI.draw(vw, vh)
  elseif cur == "cosmetics" then
     services.cosmeticsUI.draw(vw, vh)
  elseif cur == "bossGallery" then
     services.bossGallery.draw(vw, vh)
  else
    -- Center viewport for gameplay states
    services.scaling.pushViewport(centerPanel)
    if cur == "play" or cur == "pause" or cur == "gameover" then
      services.screenshake.apply()
      -- draw world relative to center viewport origin
      services.game.draw()
      services.screenshake.pop()
      local score, lives, wave = services.game.getHUD()
      services.hud.draw(score, lives, wave, centerPanel.w, centerPanel.h)
      if cur == "pause" then
        services.pauseUI.draw(centerPanel.w, centerPanel.h)
      elseif cur == "gameover" then
        local scoreOnly = select(1, services.game.getHUD())
        services.gameoverUI.draw(scoreOnly, centerPanel.w, centerPanel.h)
      end
    end
    services.scaling.popViewport()

    -- Side panels frame + controls
    services.scaling.pushViewport(leftPanel)
    services.hud.drawPanelFrame(leftPanel.w, leftPanel.h)
    if cur == "play" then services.hud.drawLeftControls(leftPanel.w, leftPanel.h) end
    services.scaling.popViewport()
    services.scaling.pushViewport(rightPanel)
    services.hud.drawPanelFrame(rightPanel.w, rightPanel.h)
    if cur == "play" then services.hud.drawRightControls(rightPanel.w, rightPanel.h) end
    services.scaling.popViewport()
  end

  services.scaling.finish()

  if SHOW_DEBUG_TOUCH then
    services.input.drawDebug()
  end

  -- Draw tutorial overlay if active
  services.tutorial.draw(vw, vh)

  -- Debug overlay with FPS and entity counts
  if SHOW_DEBUG_OVERLAY then
    drawDebugOverlay()
  end
end

-- Draw debug overlay with performance metrics
function drawDebugOverlay()
  local font = love.graphics.getFont()
  local fps = love.timer.getFPS()
  
  -- Count active entities
  local bulletCount = 0
  local alienCount = 0
  local particleCount = 0
  
  -- Count bullets
  local Bullets = require("src.game.bullets")
  Bullets.eachActive(function() bulletCount = bulletCount + 1 end)
  
  -- Get game state for additional info
  local curState = services.state.get()
  local score, lives, wave = 0, 0, 0
  if curState == "play" or curState == "pause" or curState == "gameover" then
    score, lives, wave = services.game.getHUD()
  end
  
  -- Draw overlay background
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.rectangle("fill", 10, 10, 200, 120)
  
  -- Draw text
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("DEBUG OVERLAY", 15, 15)
  love.graphics.print("FPS: " .. fps, 15, 35)
  love.graphics.print("State: " .. curState, 15, 50)
  love.graphics.print("Bullets: " .. bulletCount, 15, 65)
  love.graphics.print("Score: " .. score, 15, 80)
  love.graphics.print("Lives: " .. lives, 15, 95)
  love.graphics.print("Wave: " .. wave, 15, 110)
  
  -- Instructions
  love.graphics.setColor(1, 1, 0, 1)
  love.graphics.print("Press F2 to toggle", 15, 130)
end
