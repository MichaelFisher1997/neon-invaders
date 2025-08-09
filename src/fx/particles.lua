local Particles = {}

local pool = {}
local max = 256

local function newP()
  return { x=0,y=0, dx=0,dy=0, life=0, maxLife=0.6, size=2, r=1,g=1,b=1,a=1, active=false }
end

function Particles.init()
  pool = {}
  for i=1,max do pool[i] = newP() end
end

local function getFree()
  for i=1,#pool do if not pool[i].active then return pool[i] end end
  local p = newP(); table.insert(pool,p); return p
end

function Particles.burst(x, y, color, count, speed)
  count = count or 16
  speed = speed or 160
  for i=1,count do
    local p = getFree()
    local ang = math.random()*math.pi*2
    local sp = speed*(0.4 + math.random()*0.6)
    p.x, p.y = x, y
    p.dx = math.cos(ang)*sp
    p.dy = math.sin(ang)*sp
    p.life = p.maxLife*(0.6 + math.random()*0.5)
    p.size = 1 + math.random()*2
    p.r, p.g, p.b, p.a = color[1], color[2], color[3], 1
    p.active = true
  end
end

function Particles.update(dt)
  for i=1,#pool do
    local p = pool[i]
    if p.active then
      p.life = p.life - dt
      if p.life <= 0 then p.active = false else
        p.x = p.x + p.dx*dt
        p.y = p.y + p.dy*dt
        p.a = p.life / p.maxLife
      end
    end
  end
end

function Particles.draw()
  for i=1,#pool do
    local p = pool[i]
    if p.active then
      love.graphics.setColor(p.r, p.g, p.b, p.a)
      love.graphics.rectangle("fill", p.x, p.y, p.size, p.size)
    end
  end
end

return Particles
