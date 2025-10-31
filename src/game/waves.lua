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
  -- Progressive scaling with plateaus for better playability
  local speedTier = math.min(math.floor((waveIndex - 1) / 10), 5) -- Plateaus every 10 waves
  local baseSpeed = Constants.WAVE.baseSpeed + (Constants.WAVE.speedIncrement * 3) * speedTier -- Slower scaling
  baseSpeed = math.min(baseSpeed, Constants.WAVE.maxSpeed) -- Cap speed
  local formationSpeed = baseSpeed * mult.speed
  
  local fireRateTier = math.min(math.floor((waveIndex - 1) / 8), 6) -- Plateaus every 8 waves  
  local baseFireRate = Constants.WAVE.baseFireRate + (Constants.WAVE.fireRateIncrement * 2) * fireRateTier -- Slower scaling
  baseFireRate = math.min(baseFireRate, Constants.WAVE.maxFireRate) -- Cap fire rate
  local enemyFireRate = baseFireRate * mult.fire
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
