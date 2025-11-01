local State = {}

local current = "title"
local pendingTransition = nil
local transitionTimer = 0
local transitionDelay = 0.5

function State.set(name, delay)
  if delay and delay > 0 then
    pendingTransition = name
    transitionTimer = delay
  else
    current = name
    pendingTransition = nil
    transitionTimer = 0
  end
end

function State.setWithDelay(name)
  State.set(name, transitionDelay)
end

function State.update(dt)
  if pendingTransition and transitionTimer > 0 then
    transitionTimer = transitionTimer - dt
    if transitionTimer <= 0 then
      current = pendingTransition
      pendingTransition = nil
      transitionTimer = 0
    end
  end
end

function State.get()
  return current
end

function State.isTransitioning()
  return pendingTransition ~= nil
end

return State
