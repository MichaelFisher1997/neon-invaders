local Settings = require("src.systems.settings")
local Synth = require("src.audio.synth")

local Audio = {}

local sounds = {}
local music

function Audio.load()
  sounds = {
    ui_click = Synth.beep(660, 0.07, 'sine'),
    player_shoot = Synth.beep(880, 0.06, 'triangle'),
    enemy_shoot = Synth.beep(330, 0.06, 'square'),
    hit = Synth.beep(200, 0.10, 'triangle'),
    explosion = Synth.beep(140, 0.16, 'triangle'),
    wave_cleared = Synth.beep(880, 0.18, 'sine'),
    boss_entrance = Synth.beep(300, 0.24, 'sine'),
  }
  for _, s in pairs(sounds) do s:setVolume(Settings.get().sfxVolume) end
  music = Synth.musicLoop()
  music:setLooping(true)
  music:setVolume(Settings.get().musicVolume)
  Audio.music = music
end

local function setVolumes()
  local s = Settings.get()
  if music then music:setVolume(s.musicVolume) end
  for _, src in pairs(sounds) do
    src:setVolume(s.sfxVolume)
  end
end

function Audio.play(id)
  local src = sounds[id]
  if src then src:stop(); src:play() end
end

function Audio.update()
  setVolumes()
end

function Audio.setMusic(source)
  music = source
  if music then
    music:setLooping(true)
    music:play()
  end
  setVolumes()
end

function Audio.toggleMusic(on)
  if not music then return end
  if on == false then music:stop() else if not music:isPlaying() then music:play() end end
end

return Audio
