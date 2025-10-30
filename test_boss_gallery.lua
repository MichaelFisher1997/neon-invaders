#!/usr/bin/env lua

-- Simple test for boss gallery positioning
package.path = package.path .. ";./src/?.lua;./src/?/?.lua"

-- Mock love2d functions
local love = {}
love.graphics = {}
love.graphics.setColor = function() end
love.graphics.rectangle = function() end
love.graphics.push = function() end
love.graphics.pop = function() end
love.graphics.translate = function() end

local function createMockFont()
  local font = {}
  font.getWidth = function() return 100 end
  return font
end

love.graphics.newFont = createMockFont
love.graphics.print = function() end
love.graphics.printf = function() end
love.graphics.getFont = createMockFont
_G.love = love

-- Test boss gallery loading
local BossGallery = require("src.ui.bossgallery")

print("✓ Boss gallery module loaded successfully")

-- Test spawning demo boss
BossGallery.enter()
print("✓ Boss gallery entered successfully")

BossGallery.spawnDemoBoss(1)
print("✓ Demo boss 1 spawned successfully")

BossGallery.spawnDemoBoss(2)
print("✓ Demo boss 2 spawned successfully")

print("\n✅ All boss gallery tests passed!")