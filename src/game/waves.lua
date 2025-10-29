local Settings = require("src.systems.settings")
local Constants = require("src.config.constants")

local Waves = {}

local function difficultyMultipliers()
  local d = Settings.get().difficulty or 'normal'
  return Constants.DIFFICULTY[d]
end

--- Generate wave configuration for given wave index
--- @param waveIndex number The wave number (1-based)
--- @return table Wave configuration with properties: wave, formationSpeed, enemyFireRate, cols, rows, stepDown, boss, playerLivesBonus
function Waves.configFor(waveIndex)
  local mult = difficultyMultipliers()
  -- Base curves per spec
  local baseSpeed = Constants.WAVE.baseSpeed + Constants.WAVE.speedIncrement * (waveIndex - 1)
  local formationSpeed = baseSpeed * mult.speed
  local enemyFireRate = (Constants.WAVE.baseFireRate + Constants.WAVE.fireRateIncrement * (waveIndex - 1)) * mult.fire
  local cols = math.min(Constants.WAVE.maxCols, Constants.WAVE.baseCols + math.floor((waveIndex-1)/2))
  -- Start with 1 row and add +1 each wave up to 6; placement will ensure a 2-row safety buffer from the player
  local rows = math.min(Constants.WAVE.maxRows, Constants.WAVE.baseRows + (waveIndex - 1))
  local stepDown = Constants.WAVE.stepDownDistance + mult.stepDownAdd
  local isBoss = (waveIndex % Constants.WAVE.bossInterval == 0)
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
