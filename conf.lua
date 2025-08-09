function love.conf(t)
  t.identity = "neon-invaders"
  t.version = "11.5"
  t.console = false

  t.window.title = "Neon Invaders"
  t.window.width = 1280
  t.window.height = 720
  t.window.resizable = true
  t.window.highdpi = true
  t.window.vsync = 1

  t.modules.audio = true
  t.modules.event = true
  t.modules.graphics = true
  t.modules.image = true
  t.modules.joystick = false
  t.modules.keyboard = true
  t.modules.math = true
  t.modules.mouse = true
  t.modules.physics = false
  t.modules.sound = true
  t.modules.system = true
  t.modules.timer = true
  t.modules.touch = true
  t.modules.video = false
  t.modules.window = true
end
