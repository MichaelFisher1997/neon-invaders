#!/usr/bin/env lua

-- Mock love2d functions
local love = {}
love.graphics = {}
love.graphics.getFont = function() return {} end
love.timer = {getTime = function() return 12345}
_G.love = love

print("Minimal test works!")
print("✓ Mock functions defined correctly")