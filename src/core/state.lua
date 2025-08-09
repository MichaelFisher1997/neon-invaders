local State = {}

local current = "title"

function State.set(name)
  current = name
end

function State.get()
  return current
end

return State
