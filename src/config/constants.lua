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
  maxSpeed = 150, -- Cap speed to maintain playability
  baseFireRate = 0.6,
  fireRateIncrement = 0.08,
  maxFireRate = 3.0, -- Cap fire rate to prevent bullet hell
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

-- Alien variants
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

-- Economy/Upgrade constants
Constants.ECONOMY = {
  -- Currency conversion rates
  scoreToCreditsRate = 0.01, -- 1% of score converted to credits
  bossKillBonus = 1000, -- 10x bonus for killing boss (was 100)
  specialAlienBonus = 25, -- Bonus for killing special aliens
  
  -- Upgrade costs and effects (ordered by accessibility)
  upgrades = {
    speed = {
      name = "Ship Speed",
      baseCost = 200,
      costMultiplier = 4.0,
      maxLevel = 6,
      effectPerLevel = 0.15, -- +15% speed per level
      description = "Increases ship movement speed by 15% per level"
    },
    damage = {
      name = "Damage",
      baseCost = 300,
      costMultiplier = 4.5,
      maxLevel = 10,
      effectPerLevel = 0.25, -- +25% damage per level
      description = "Increases bullet damage by 25% per level"
    },
    fireRate = {
      name = "Fire Rate",
      baseCost = 400,
      costMultiplier = 5.0,
      maxLevel = 8,
      effectPerLevel = 0.2, -- +20% fire rate per level
      description = "Increases fire rate by 20% per level"
    },
    piercing = {
      name = "Piercing Rounds",
      baseCost = 3000,
      costMultiplier = 8.0,
      maxLevel = 5,
      effectPerLevel = 1, -- +1 piercing level
      description = "Bullets pierce through 1-5 enemies"
    },
    multiShot = {
      name = "Multi-Shot",
      baseCost = 5000,
      costMultiplier = 10.0,
      maxLevel = 3,
      effectPerLevel = 1, -- +1 additional shot per level
      description = "Adds 1 additional bullet per shot"
    }
  },
  
  -- Cosmetics shop
  cosmetics = {
    colors = {
      red = {
        name = "Crimson Red",
        cost = 200,
        color = {1.0, 0.25, 0.25, 1.0},
        description = "Bold red ship color"
      },
      blue = {
        name = "Ocean Blue", 
        cost = 300,
        color = {0.30, 0.55, 1.00, 1.0},
        description = "Deep blue ship color"
      },
      green = {
        name = "Neon Green",
        cost = 400,
        color = {0.20, 1.00, 0.35, 1.0},
        description = "Bright green ship color"
      },
      purple = {
        name = "Royal Purple",
        cost = 600,
        color = {0.8, 0.2, 1.0, 1.0},
        description = "Elegant purple ship color"
      },
      gold = {
        name = "Golden",
        cost = 800,
        color = {1.0, 0.8, 0.2, 1.0},
        description = "Shiny gold ship color"
      },
      cyan = {
        name = "Electric Cyan",
        cost = 1000,
        color = {0.2, 1.0, 0.8, 1.0},
        description = "Vibrant cyan ship color"
      },
      orange = {
        name = "Blazing Orange",
        cost = 1200,
        color = {1.0, 0.5, 0.1, 1.0},
        description = "Fiery orange ship color"
      },
      pink = {
        name = "Hot Pink",
        cost = 1500,
        color = {1.0, 0.3, 0.6, 1.0},
        description = "Vivid pink ship color"
      },
      rgb_trip = {
        name = "RGB Morph",
        cost = 2500,
        color = {1.0, 1.0, 1.0, 1.0}, -- Dynamic color
        description = "Fast RGB color morphing effect"
      }
    },
    shapes = {
      triangle = {
        name = "Triangle",
        cost = 0, -- Free default
        description = "Classic triangle ship"
      },
      diamond = {
        name = "Diamond",
        cost = 400,
        description = "Sleek diamond shape"
      },
      hexagon = {
        name = "Hexagon",
        cost = 800,
        description = "Hexagonal ship design"
      },
      arrow = {
        name = "Arrow",
        cost = 600,
        description = "Sharp arrow shape"
      },
      circle = {
        name = "Circle",
        cost = 1000,
        description = "Compact circular ship"
      },
      star = {
        name = "Star",
        cost = 1600,
        description = "Five-pointed star ship"
      }
    }
  }
}

return Constants