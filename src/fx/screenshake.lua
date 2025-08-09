local Screenshake = {}

local t = 0
local strength = 0

function Screenshake.add(duration, amount)
  t = math.max(t, duration or 0.15)
  strength = math.max(strength, amount or 6)
end

function Screenshake.update(dt)
  if t > 0 then
    t = t - dt
    if t <= 0 then t = 0; strength = 0 end
  end
end

local function jitter()
  if t <= 0 then return 0, 0 end
  local decay = t -- simple linear decay
  local ox = (math.random()*2-1) * strength * decay
  local oy = (math.random()*2-1) * strength * decay
  return ox, oy
end

function Screenshake.apply()
  love.graphics.push()
  local ox, oy = jitter()
  love.graphics.translate(ox, oy)
end

function Screenshake.pop()
  love.graphics.pop()
end

return Screenshake
