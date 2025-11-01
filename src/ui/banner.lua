local Banner = {}
local Fonts = require("src.ui.fonts")

local t = 0
local text = ""

function Banner.trigger(msg)
  text = msg or "WAVE CLEARED!"
  t = 1.8
end

function Banner.update(dt)
  if t > 0 then t = t - dt if t < 0 then t = 0 end end
end

function Banner.draw(vw, vh)
  if t <= 0 then return end
  local alpha = math.min(1, t)
  love.graphics.setFont(Fonts.get(36))
  love.graphics.setColor(1, 1, 1, alpha)
  love.graphics.printf(text, 0, vh*0.42, vw, 'center')
end

function Banner.isActive() return t > 0 end

return Banner