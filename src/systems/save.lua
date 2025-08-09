local Save = {}

local function ensureDir()
  -- LÖVE ensures write dir; nothing to do
end

function Save.saveLua(tableName, tbl)
  ensureDir()
  local serialized = "return " .. Save.serialize(tbl)
  love.filesystem.write(tableName, serialized)
end

function Save.loadLua(tableName, default)
  if not love.filesystem.getInfo(tableName) then return default end
  local chunk = love.filesystem.load(tableName)
  local ok, result = pcall(chunk)
  if ok and type(result) == "table" then return result else return default end
end

function Save.serialize(value, indent)
  indent = indent or 0
  local t = type(value)
  if t == "number" or t == "boolean" then
    return tostring(value)
  elseif t == "string" then
    return string.format("%q", value)
  elseif t == "table" then
    local parts = {"{"}
    local first = true
    for k, v in pairs(value) do
      if not first then table.insert(parts, ",") end
      first = false
      local key
      if type(k) == "string" and k:match("^[_%a][_%w]*$") then
        key = k .. " = "
      else
        key = "[" .. Save.serialize(k, indent+2) .. "] = "
      end
      table.insert(parts, "\n" .. string.rep(" ", indent+2) .. key .. Save.serialize(v, indent+2))
    end
    table.insert(parts, "\n" .. string.rep(" ", indent) .. "}")
    return table.concat(parts)
  else
    return "nil"
  end
end

return Save
