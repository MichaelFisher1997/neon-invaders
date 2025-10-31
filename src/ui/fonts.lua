local Fonts = {}

local cache = {}

function Fonts.get(size, path)
  local key = tostring(size) .. "|" .. (path or "default")

  if not cache[key] then
    if path then
      cache[key] = love.graphics.newFont(path, size)
    else
      cache[key] = love.graphics.newFont(size)
    end
  end

  return cache[key]
end

function Fonts.reset()
  cache = {}
end

function Fonts.set(size, path)
  love.graphics.setFont(Fonts.get(size, path))
end

return Fonts