#!/usr/bin/env lua

-- Script to check for love.graphics.newFont calls in draw functions
-- This helps prevent font allocations in render paths

local function checkFile(filePath)
  local file = io.open(filePath, "r")
  if not file then return false end
  
  local content = file:read("*all")
  file:close()
  
  local lines = {}
  for line in content:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  
  local inDrawFunction = false
  local drawFunctionDepth = 0
  local violations = {}
  
  for i, line in ipairs(lines) do
    -- Track if we're inside a draw function
    if line:match("function%.draw") or line:match("function.*draw") or line:match("draw%s*=%s*function") then
      inDrawFunction = true
      drawFunctionDepth = 1
    elseif line:match("function") and inDrawFunction then
      drawFunctionDepth = drawFunctionDepth + 1
    elseif line:match("^end") and inDrawFunction then
      drawFunctionDepth = drawFunctionDepth - 1
      if drawFunctionDepth == 0 then
        inDrawFunction = false
      end
    end
    
    -- Check for newFont calls in draw functions
    if inDrawFunction and line:match("love%.graphics%.newFont") then
      table.insert(violations, {
        line = i,
        content = line:gsub("^%s+", "")
      })
    end
  end
  
  if #violations > 0 then
    print("❌ " .. filePath .. " - Found " .. #violations .. " font allocation(s) in draw functions:")
    for _, violation in ipairs(violations) do
      print("   Line " .. violation.line .. ": " .. violation.content)
    end
    return false
  end
  
  return true
end

-- Check all Lua files in src/
local function checkDirectory(dir)
  local handle = io.popen('find "' .. dir .. '" -name "*.lua"')
  local files = {}
  for file in handle:lines() do
    table.insert(files, file)
  end
  handle:close()
  
  local allGood = true
  for _, file in ipairs(files) do
    if not checkFile(file) then
      allGood = false
    end
  end
  
  return allGood
end

print("🔍 Checking for font allocations in draw functions...")
print()

local success = checkDirectory("src")

print()
if success then
  print("✅ No font allocations found in draw functions!")
else
  print("❌ Found font allocations that should be cached!")
  os.exit(1)
end