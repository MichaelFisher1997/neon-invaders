local Constants = {}

-- Colors from main.lua
Constants.COLORS = {
  bg = {0.04, 0.04, 0.06, 1.0},
  cyan = {0.153, 0.953, 1.0, 1.0},
  magenta = {1.0, 0.182, 0.651, 1.0},
  purple = {0.541, 0.169, 0.886, 1.0},
  white = {1, 1, 1, 1},
}

-- Game constants
Constants.VIRTUAL_WIDTH = 1280
Constants.VIRTUAL_HEIGHT = 720

-- Player constants
Constants.PLAYER = {
  speed = 360,
  fireRate = 4.0,
  width = 40,
  height = 18,
  margin = 24,
  bulletSpeed = 640,
  respawnTime = 0.8,
  invincibilityTime = 2.2,
  spawnY = 64, -- distance from bottom
}

-- Bullet constants
Constants.BULLET = {
  radius = 4,
  poolSize = 128,
  offscreenMargin = 16,
}

-- Wave constants
Constants.WAVE = {
  baseSpeed = 60,
  speedIncrement = 10,
  baseFireRate = 0.6,
  fireRateIncrement = 0.08,
  baseCols = 8,
  maxCols = 12,
  baseRows = 1,
  maxRows = 6,
  stepDownDistance = 24,
  bossInterval = 5,
}

-- Difficulty multipliers
Constants.DIFFICULTY = {
  easy = {
    speed = 0.9,
    fire = 0.8,
    stepDownAdd = 0,
    playerLivesBonus = 1,
  },
  normal = {
    speed = 1.0,
    fire = 1.0,
    stepDownAdd = 0,
    playerLivesBonus = 0,
  },
  hard = {
    speed = 1.10,
    fire = 1.15,
    stepDownAdd = 0,
    playerLivesBonus = 0,
  },
}

return Constants