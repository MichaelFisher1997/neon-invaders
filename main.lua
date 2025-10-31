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
  local action = services.input.keypressed(key)
  
  local curState = services.state.get()
  if curState == "title" then
    if action == "Start" then
      local gw, gh = services.scaling.getVirtualSize()
      services.game.init(gw, gh)
      services.state.set("play")
    elseif action == "Upgrades" then
      services.state.set("upgradeMenu")
      services.upgradeMenu.init()
    elseif action == "Boss Gallery" then
      services.bossGallery.enter()
      services.state.setWithDelay("bossGallery")
    elseif action == "Cosmetics" then
      services.cosmeticsUI.enter()
      services.state.setWithDelay("cosmetics")
    elseif action == "Settings" then
      services.settingsUI.enter()
      services.state.setWithDelay("settings")
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
    end
  elseif curState == "cosmetics" then
    if action == 'back' then
      services.state.set("title")
      services.title.enter()
    end
  elseif curState == "bossGallery" then
    if action == 'title' then
      services.state.set("title")
      services.title.enter()
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
    end
  end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
  services.inputMode.onTouchPressed()
  services.input.touchpressed(id, x, y, dx, dy, pressure)
end

function love.touchmoved(id, x, y, dx, dy, pressure)
  services.input.touchmoved(id, x, y, dx, dy, pressure)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
  services.input.touchreleased(id, x, y, dx, dy, pressure)
end

function love.update(dt)
  services.state.update(dt)
  
  local curState = services.state.get()
  local handler = uiHandlers[curState]
  if handler and handler.update then
    handler.update(dt)
  end
  
  -- Update global systems
  services.starfield.update(dt)
  services.screenshake.update(dt)
  services.audio.update(dt)
  
  -- Update delayed transitions
  services.state.update(dt)
end

function love.draw()
  services.scaling.begin()
  
  local vw, vh = services.scaling.getVirtualSize()
  
  -- Draw background
  services.starfield.draw(vw, vh)
  
  local curState = services.state.get()
  local handler = uiHandlers[curState]
  if handler and handler.draw then
    handler.draw(vw, vh)
  end
  
  -- Draw debug overlay if enabled
  if SHOW_DEBUG_TOUCH then
    love.graphics.setColor(1, 0, 0, 0.5)
    local touches = love.touch.getTouches()
    for id, touch in pairs(touches) do
      love.graphics.circle('fill', touch.x, touch.y, 20)
    end
  end
  
  services.scaling.finish()
end
