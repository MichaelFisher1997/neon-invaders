local Starfield = {}

local VIRTUAL_WIDTH, VIRTUAL_HEIGHT = 1280, 720

local layers = {}

local PALETTE = {
  {0.153, 0.953, 1.000, 1.0}, -- cyan #27f3ff
  {1.000, 0.182, 0.651, 1.0}, -- magenta #ff2ea6
  {0.541, 0.169, 0.886, 1.0}, -- purple #8a2be2
  {1.000, 1.000, 1.000, 1.0}, -- white
}

local function randRange(a, b)
  return a + math.random() * (b - a)
end

local function initLayer(count, speedMin, speedMax, sizeMin, sizeMax)
  local stars = {}
  for i = 1, count do
    stars[i] = {
      x = math.random() * VIRTUAL_WIDTH,
      y = math.random() * VIRTUAL_HEIGHT,
      speed = randRange(speedMin, speedMax),
      size = randRange(sizeMin, sizeMax),
      color = PALETTE[math.random(1, #PALETTE)],
    }
  end
  return stars
end

function Starfield.init(virtualW, virtualH)
  VIRTUAL_WIDTH, VIRTUAL_HEIGHT = virtualW or 1280, virtualH or 720
  math.randomseed(os.time())
  local area = VIRTUAL_WIDTH * VIRTUAL_HEIGHT
  local density = area / (1280 * 720)
  layers = {
    initLayer(math.floor(90 * density), 20, 40, 1.0, 1.5), -- far
    initLayer(math.floor(60 * density), 50, 90, 1.2, 2.0), -- near
  }
end

function Starfield.update(dt)
  for _, stars in ipairs(layers) do
    for i = 1, #stars do
      local s = stars[i]
      s.y = s.y + s.speed * dt
      if s.y > VIRTUAL_HEIGHT + 2 then
        s.y = -2
        s.x = math.random() * VIRTUAL_WIDTH
      end
    end
  end
end

function Starfield.draw()
  for _, stars in ipairs(layers) do
    for i = 1, #stars do
      local s = stars[i]
      love.graphics.setColor(s.color)
      love.graphics.rectangle("fill", s.x, s.y, s.size, s.size)
    end
  end
end

return Starfield
