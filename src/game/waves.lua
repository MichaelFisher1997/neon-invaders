local Settings = require("src.systems.settings")

local Waves = {}

local function difficultyMultipliers()
  local d = Settings.get().difficulty or 'normal'
  if d == 'easy' then
    return { speed = 0.9, fire = 0.8, stepDownAdd = 0, playerLivesBonus = 1 }
  elseif d == 'hard' then
    -- Tuning: Hard was spiking too early with faster step-down cycles and row growth.
    -- Soften multipliers to preserve challenge without early brick walls.
    return { speed = 1.10, fire = 1.15, stepDownAdd = 0, playerLivesBonus = 0 }
  else
    return { speed = 1.0, fire = 1.0, stepDownAdd = 0, playerLivesBonus = 0 }
  end
end

function Waves.configFor(waveIndex)
  local mult = difficultyMultipliers()
  -- Base curves per spec
  local baseSpeed = 60 + 10 * (waveIndex - 1)
  local formationSpeed = baseSpeed * mult.speed
  local enemyFireRate = (0.6 + 0.08 * (waveIndex - 1)) * mult.fire
  local cols = math.min(12, 8 + math.floor((waveIndex-1)/2))
  -- Start with 1 row and add +1 each wave up to 6; placement will ensure a 2-row safety buffer from the player
  local rows = math.min(6, 1 + (waveIndex - 1))
  local stepDown = 24 + mult.stepDownAdd
  local isBoss = (waveIndex % 5 == 0)
  return {
    wave = waveIndex,
    formationSpeed = formationSpeed,
    enemyFireRate = enemyFireRate,
    cols = cols,
    rows = rows,
    stepDown = stepDown,
    boss = isBoss,
    playerLivesBonus = mult.playerLivesBonus,
  }
end

return Waves
