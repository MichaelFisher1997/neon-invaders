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

-- Powerup constants
Constants.POWERUP = {
  radius = 16,
  poolSize = 16,
  offscreenMargin = 32,
  fallSpeed = 120,
  maxActive = 1, -- Only one powerup at a time
  types = {
    rapid_fire = {
      name = "Rapid Fire",
      color = {1.0, 0.8, 0.2, 1.0}, -- Gold
      duration = 4.0, -- Reduced from 8.0
      effect = { fireRateMultiplier = 1.5 } -- Reduced from 2.0
    },
    triple_shot = {
      name = "Double Shot", -- Reduced from Triple
      color = {0.2, 1.0, 0.8, 1.0}, -- Cyan
      duration = 5.0, -- Reduced from 10.0
      effect = { multiShot = 2 } -- Reduced from 3
    },
    shield = {
      name = "Shield",
      color = {0.8, 0.2, 1.0, 1.0}, -- Purple
      duration = 6.0, -- Reduced from 12.0
      effect = { invincible = true }
    },
    speed_boost = {
      name = "Speed Boost",
      color = {1.0, 0.4, 0.2, 1.0}, -- Orange
      duration = 4.0, -- Reduced from 7.0
      effect = { speedMultiplier = 1.3 } -- Reduced from 1.5
    },
    piercing = {
      name = "Piercing Shots",
      color = {1.0, 0.2, 0.4, 1.0}, -- Red
      duration = 5.0, -- Reduced from 9.0
      effect = { piercing = true }
    }
  }
}

-- Enemy variants constants
Constants.ALIEN_VARIANTS = {
  basic = {
    name = "Basic",
    color = {1.0, 0.182, 0.651, 1.0}, -- Magenta
    health = 1,
    score = 10,
    speed = 1.0,
    size = 1.0,
    behavior = "march"
  },
  tank = {
    name = "Tank",
    color = {0.8, 0.2, 0.2, 1.0}, -- Red
    health = 3,
    score = 25,
    speed = 0.6,
    size = 1.3,
    behavior = "march"
  },
  speedy = {
    name = "Speedy",
    color = {1.0, 0.8, 0.2, 1.0}, -- Gold
    health = 1,
    score = 15,
    speed = 1.8,
    size = 0.8,
    behavior = "zigzag"
  },
  sniper = {
    name = "Sniper",
    color = {0.2, 1.0, 0.8, 1.0}, -- Cyan
    health = 1,
    score = 20,
    speed = 0.8,
    size = 0.9,
    behavior = "march",
    fireRateBonus = 0.3 -- Increases enemy fire rate
  },
  ghost = {
    name = "Ghost",
    color = {0.8, 0.2, 1.0, 1.0}, -- Purple
    health = 1,
    score = 30,
    speed = 1.2,
    size = 1.0,
    behavior = "phase",
    phaseChance = 0.3 -- 30% chance to phase through bullets
  }
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