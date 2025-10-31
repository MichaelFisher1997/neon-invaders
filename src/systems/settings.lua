local Save = require("src.systems.save")

local Settings = {}

local DEFAULT = {
  musicVolume = 0.6,
  sfxVolume = 0.8,
  difficulty = 'normal',
}

local cached

function Settings.get()
  if cached then return cached end
  cached = Save.loadLua('settings.lua', DEFAULT)
  -- sanitize
  cached.musicVolume = math.max(0, math.min(1, cached.musicVolume or DEFAULT.musicVolume))
  cached.sfxVolume = math.max(0, math.min(1, cached.sfxVolume or DEFAULT.sfxVolume))
  if cached.difficulty ~= 'easy' and cached.difficulty ~= 'hard' and cached.difficulty ~= 'normal' then
    cached.difficulty = 'normal'
  end
  return cached
end

function Settings.set(key, value)
  local s = Settings.get()
  s[key] = value
end

function Settings.save()
  Save.saveLua('settings.lua', Settings.get())
end

function Settings.reset()
  cached = nil
  if love.filesystem.getInfo('settings.lua') then
    love.filesystem.remove('settings.lua')
  end
end

return Settings
