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
    piercing = 0,
    speed = 0
  },
  creditMultiplier = 1,
  currentWave = 1,
  creditMilestoneWave = 0
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
      piercing = 0,
      speed = 0
    }
  end
  state.creditMultiplier = 1
  state.currentWave = state.currentWave or 1
  state.creditMilestoneWave = state.creditMilestoneWave or 0
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
  amount = math.floor(amount or 0)
  if amount <= 0 then return 0 end
  local multiplier = state.creditMultiplier or 1
  local finalAmount = amount * multiplier
  state.credits = state.credits + finalAmount
  state.totalCreditsEarned = state.totalCreditsEarned + finalAmount
  Economy.save()
  return finalAmount
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
    return Economy.addCredits(credits)
  end
  return 0
end

-- Award boss kill bonus
function Economy.awardBossKill()
  return Economy.addCredits(Constants.ECONOMY.bossKillBonus)
end

-- Award special alien kill bonus
function Economy.awardSpecialAlienKill()
  return Economy.addCredits(Constants.ECONOMY.specialAlienBonus)
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

function Economy.getPiercingLevel()
  return state.upgrades.piercing or 0
end

function Economy.getSpeedMultiplier()
  local level = state.upgrades.speed or 0
  return 1.0 + (level * Constants.ECONOMY.upgrades.speed.effectPerLevel)
end

-- Reset economy to defaults (used by settings clear data)
function Economy.reset()
  state = {
    credits = 0,
    totalCreditsEarned = 0,
    upgrades = {
      damage = 0,
      fireRate = 0,
      multiShot = 0,
      piercing = 0,
      speed = 0
    },
    creditMultiplier = 1,
    currentWave = 1,
    creditMilestoneWave = 0
  }
  -- Also delete the save file to prevent reloading
  if love.filesystem.getInfo("economy") then
    love.filesystem.remove("economy")
  end
end

-- Debug function to add credits (remove in production)
function Economy.debugAddCredits(amount)
  Economy.addCredits(amount)
end

function Economy.updateCreditMultiplier(wave)
  local interval = Constants.ECONOMY.creditBonusInterval or 50
  state.currentWave = math.max(wave or state.currentWave or 1, 1)
  local tier = math.floor(state.currentWave / interval)
  local newMultiplier = math.max(1, 1 + tier)
  local milestoneWave = math.max(tier * interval, 0)
  local changed = newMultiplier ~= state.creditMultiplier
  state.creditMultiplier = newMultiplier
  state.creditMilestoneWave = milestoneWave
  return changed, milestoneWave
end

function Economy.getCreditMultiplier()
  return state.creditMultiplier or 1
end

function Economy.getCreditMilestoneWave()
  return state.creditMilestoneWave or 0
end

function Economy.getNextCreditMilestoneWave()
  local interval = Constants.ECONOMY.creditBonusInterval or 50
  local currentWave = state.currentWave or 1
  local nextTier = math.floor(currentWave / interval) + 1
  return nextTier * interval
end

function Economy.getCreditBonusInterval()
  return Constants.ECONOMY.creditBonusInterval or 50
end

return Economy
