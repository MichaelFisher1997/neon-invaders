local Synth = {}

local function clamp(x, a, b) return math.max(a, math.min(b, x)) end

local function makeWave(freq, duration, sampleRate, shape)
  sampleRate = sampleRate or 22050
  local length = math.floor(duration * sampleRate)
  local sd = love.sound.newSoundData(length, sampleRate, 16, 1)
  local tau = math.pi * 2
  for i = 0, length - 1 do
    local t = i / sampleRate
    local phase = t * freq
    local s
    if shape == 'square' then
      s = (math.sin(tau * phase) >= 0) and 0.4 or -0.4
    elseif shape == 'triangle' then
      s = 2 * math.abs(2 * (phase - math.floor(phase + 0.5))) - 1
      s = s * 0.45
    else -- sine
      s = math.sin(tau * phase) * 0.35
    end
    -- Apply a simple attack/decay envelope to soften transients
    local attack = 0.01
    local env = math.min(1, t / attack) * math.max(0, 1 - (t / duration))
    s = s * env
    sd:setSample(i, s)
  end
  return sd
end

function Synth.beep(freq, duration, shape)
  local sd = makeWave(freq, duration or 0.08, 22050, shape or 'square')
  return love.audio.newSource(sd, 'static')
end

function Synth.musicLoop()
  -- Simple 8-second arpeggio loop
  local sampleRate = 22050
  local total = 8.0
  local sd = love.sound.newSoundData(math.floor(total * sampleRate), sampleRate, 16, 1)
  local tau = math.pi * 2
  local steps = {
    { 440, 0.25 }, { 660, 0.25 }, { 550, 0.25 }, { 660, 0.25 },
    { 494, 0.25 }, { 740, 0.25 }, { 622, 0.25 }, { 740, 0.25 },
  }
  local tCursor = 0
  local function writeTone(freq, dur)
    local length = math.floor(dur * sampleRate)
    for i = 0, length - 1 do
      local t = i / sampleRate
      local env = math.min(1, t * 20) * math.max(0, 1 - (t / dur)) -- simple attack/decay
      local s = math.sin(tau * (freq) * t) * 0.25 * env
      sd:setSample(math.floor(tCursor * sampleRate) + i, s)
    end
    tCursor = tCursor + dur
  end
  while tCursor < total do
    for _, st in ipairs(steps) do
      if tCursor >= total then break end
      writeTone(st[1], st[2])
    end
  end
  return love.audio.newSource(sd, 'static')
end

return Synth
