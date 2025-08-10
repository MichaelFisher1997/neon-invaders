local scaling = require("src.systems.scaling")
local starfield = require("src.fx.starfield")
local input = require("src.core.input")
local state = require("src.core.state")
local game = require("src.game.game")
local hud = require("src.ui.hud")
local title = require("src.ui.title")
local pauseUI = require("src.ui.pause")
local gameoverUI = require("src.ui.gameover")
local screenshake = require("src.fx.screenshake")
local settingsUI = require("src.ui.settings")
local settings = require("src.systems.settings")
local upgrades = require("src.game.upgrades")
local audio = require("src.audio.audio")

local SHOW_DEBUG_TOUCH = false

local COLORS = {
  bg = {0.04, 0.04, 0.06, 1.0},
  cyan = {0.153, 0.953, 1.0, 1.0},
  magenta = {1.0, 0.182, 0.651, 1.0},
  purple = {0.541, 0.169, 0.886, 1.0},
  white = {1, 1, 1, 1},
}

function love.load()
  scaling.setup()
  local vw, vh = scaling.getVirtualSize()
  starfield.init(vw, vh)
  love.window.setTitle("Neon Invaders")
  state.set("title")
  audio.load()
  audio.setMusic(audio.music)
end

function love.resize(w, h)
  scaling.resize(w, h)
end

function love.keypressed(key)
  input.keypressed(key)
  if key == "f1" then SHOW_DEBUG_TOUCH = not SHOW_DEBUG_TOUCH end
  if state.get() == "title" then
    title.keypressed(key)
    if key == "space" or key == "return" or key == "enter" then
      local sel = title.getSelected()
      if sel == "Start" then
        local vw, vh = scaling.getVirtualSize()
        game.init(vw, vh)
        state.set("play")
      elseif sel == "Settings" then
        state.set("settings")
      elseif sel == "Quit" then
        love.event.quit()
      end
    end
  elseif state.get() == "play" and upgrades.isShowing() then
    -- Handle upgrade overlay input BEFORE normal play handling
    upgrades.keypressed(key)
    if key == "return" or key == "enter" then
      local Player = require('src.game.player')
      upgrades.applyTo(Player)
    end
    return
  elseif state.get() == "play" then
    if key == "escape" then
      state.set("pause")
    end
  elseif state.get() == "pause" then
    if key == "escape" then state.set("play") end
    if key == "r" then local vw, vh = scaling.getVirtualSize(); game.init(vw, vh); state.set("play") end
    if key == "q" then state.set("title") end
  elseif state.get() == "gameover" then
    if key == "return" or key == "enter" then local vw, vh = scaling.getVirtualSize(); game.init(vw, vh); state.set("play") end
    if key == "q" then state.set("title") end
  elseif state.get() == "settings" then
    settingsUI.keypressed(key)
    if key == "return" or key == "enter" then settings.save(); state.set("title") end
  end
end

function love.update(dt)
  scaling.update()
  input.update(dt)
  starfield.update(dt)
  screenshake.update(dt)
  local cur = state.get()
  if cur == "title" then
    title.update(dt)
    -- Start on any touch as well
    if #love.touch.getTouches() > 0 then
      local vw, vh = scaling.getVirtualSize()
      game.init(vw, vh)
      state.set("play")
    end
  elseif cur == "settings" then
    settingsUI.update(dt)
  elseif cur == "play" then
    game.update(dt, input.get())
    if game.isOver() then state.set("gameover") end
  elseif cur == "pause" then
    -- paused, no game update
  elseif cur == "gameover" then
    -- awaiting input
  end
end

function love.draw()
  scaling.begin()

  local vw, vh = scaling.getVirtualSize()
  local leftPanel, centerPanel, rightPanel = scaling.getPanelsVirtual()
  local cur = state.get()

  -- Draw background only in center viewport to avoid space behind controls
  scaling.pushViewport(centerPanel)
  starfield.draw()
  scaling.popViewport()

  if cur == "title" then
    title.draw(vw, vh)
  elseif cur == "settings" then
    settingsUI.draw(vw, vh)
  else
    -- Center viewport for gameplay states
    scaling.pushViewport(centerPanel)
    if cur == "play" or cur == "pause" or cur == "gameover" then
      screenshake.apply()
      -- draw world relative to center viewport origin
      game.draw()
      screenshake.pop()
      local score, lives, wave = game.getHUD()
      hud.draw(score, lives, wave, centerPanel.w, centerPanel.h)
      if cur == "pause" then
        pauseUI.draw(centerPanel.w, centerPanel.h)
      elseif cur == "gameover" then
        local scoreOnly = select(1, game.getHUD())
        gameoverUI.draw(scoreOnly, centerPanel.w, centerPanel.h)
      end
      if upgrades.isShowing() then upgrades.draw(centerPanel.w, centerPanel.h) end
    end
    scaling.popViewport()

    -- Side panels frame + controls
    -- Always draw framed side panels; draw controls during play
    scaling.pushViewport(leftPanel)
    hud.drawPanelFrame(leftPanel.w, leftPanel.h)
    if cur == "play" then hud.drawLeftControls(leftPanel.w, leftPanel.h) end
    scaling.popViewport()
    scaling.pushViewport(rightPanel)
    hud.drawPanelFrame(rightPanel.w, rightPanel.h)
    if cur == "play" then hud.drawRightControls(rightPanel.w, rightPanel.h) end
    scaling.popViewport()
  end

  scaling.finish()

  if SHOW_DEBUG_TOUCH then
    input.drawDebug()
  end
end
