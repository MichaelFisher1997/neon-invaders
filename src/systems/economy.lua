local Economy = {}
local Constants = require("src.config.constants")
local Save = require("src.systems.save")

-- Economy state
local state = {
  credits = 0,
  totalCreditsEarned = 0,
  upgrades = {
    damage = 0,
    fireRate = 0,
    multiShot = 0,
    speed = 0
  }
}

-- Initialize economy system
function Economy.init()
  -- Load saved data if exists
  local savedData = Save.loadLua("economy")
  if savedData then
    state.credits = savedData.credits or 0
    state.totalCreditsEarned = savedData.totalCreditsEarned or 0
    state.upgrades = savedData.upgrades or {
      damage = 0,
      fireRate = 0,
      multiShot = 0,
      speed = 0
    }
  end
end

-- Save economy data
function Economy.save()
  Save.saveLua("economy", {
    credits = state.credits,
    totalCreditsEarned = state.totalCreditsEarned,
    upgrades = state.upgrades
  })
end

-- Add credits to player's balance
function Economy.addCredits(amount)
  state.credits = state.credits + amount
  state.totalCreditsEarned = state.totalCreditsEarned + amount
  Economy.save()
end

-- Spend credits (returns true if successful)
function Economy.spendCredits(amount)
  if state.credits >= amount then
    state.credits = state.credits - amount
    Economy.save()
    return true
  end
  return false
end

-- Get current credits
function Economy.getCredits()
  return state.credits
end

-- Get total credits earned (for stats)
function Economy.getTotalCreditsEarned()
  return state.totalCreditsEarned
end

-- Convert score to credits
function Economy.convertScore(score)
  local credits = math.floor(score * Constants.ECONOMY.scoreToCreditsRate)
  if credits > 0 then
    Economy.addCredits(credits)
  end
  return credits
end

-- Award boss kill bonus
function Economy.awardBossKill()
  Economy.addCredits(Constants.ECONOMY.bossKillBonus)
end

-- Award special alien kill bonus
function Economy.awardSpecialAlienKill()
  Economy.addCredits(Constants.ECONOMY.specialAlienBonus)
end

-- Get upgrade level
function Economy.getUpgradeLevel(upgradeType)
  return state.upgrades[upgradeType] or 0
end

-- Get upgrade cost for next level
function Economy.getUpgradeCost(upgradeType)
  local upgrade = Constants.ECONOMY.upgrades[upgradeType]
  if not upgrade then return nil end
  
  local currentLevel = state.upgrades[upgradeType] or 0
  if currentLevel >= upgrade.maxLevel then return nil end
  
  return math.floor(upgrade.baseCost * (upgrade.costMultiplier ^ currentLevel))
end

-- Check if upgrade can be purchased
function Economy.canPurchaseUpgrade(upgradeType)
  local cost = Economy.getUpgradeCost(upgradeType)
  return cost and state.credits >= cost
end

-- Purchase upgrade
function Economy.purchaseUpgrade(upgradeType)
  local upgrade = Constants.ECONOMY.upgrades[upgradeType]
  if not upgrade then return false, "Invalid upgrade type" end
  
  local currentLevel = state.upgrades[upgradeType] or 0
  if currentLevel >= upgrade.maxLevel then return false, "Max level reached" end
  
  local cost = Economy.getUpgradeCost(upgradeType)
  if not cost then return false, "Cannot calculate cost" end
  
  if Economy.spendCredits(cost) then
    state.upgrades[upgradeType] = currentLevel + 1
    Economy.save()
    return true, "Upgrade purchased!"
  else
    return false, "Not enough credits"
  end
end

-- Get all upgrade info for UI
function Economy.getUpgradeInfo()
  local info = {}
  for upgradeType, upgrade in pairs(Constants.ECONOMY.upgrades) do
    local currentLevel = state.upgrades[upgradeType] or 0
    local cost = Economy.getUpgradeCost(upgradeType)
    local canPurchase = Economy.canPurchaseUpgrade(upgradeType)
    
    info[upgradeType] = {
      name = upgrade.name,
      description = upgrade.description,
      currentLevel = currentLevel,
      maxLevel = upgrade.maxLevel,
      cost = cost,
      canPurchase = canPurchase,
      effectPerLevel = upgrade.effectPerLevel
    }
  end
  return info
end

-- Get upgrade multipliers for gameplay
function Economy.getDamageMultiplier()
  local level = state.upgrades.damage or 0
  return 1.0 + (level * Constants.ECONOMY.upgrades.damage.effectPerLevel)
end

function Economy.getFireRateMultiplier()
  local level = state.upgrades.fireRate or 0
  return 1.0 + (level * Constants.ECONOMY.upgrades.fireRate.effectPerLevel)
end

function Economy.getMultiShotCount()
  local level = state.upgrades.multiShot or 0
  return 1 + (level * Constants.ECONOMY.upgrades.multiShot.effectPerLevel)
end

function Economy.getSpeedMultiplier()
  local level = state.upgrades.speed or 0
  return 1.0 + (level * Constants.ECONOMY.upgrades.speed.effectPerLevel)
end

-- Reset economy (for testing/new game)
function Economy.reset()
  state.credits = 0
  state.totalCreditsEarned = 0
  state.upgrades = {
    damage = 0,
    fireRate = 0,
    multiShot = 0,
    speed = 0
  }
  Economy.save()
end

-- Debug function to add credits (remove in production)
function Economy.debugAddCredits(amount)
  Economy.addCredits(amount)
end

return Economy