local Save = require("src.systems.save")

local Highscores = {}

local FILENAME = 'highscores.lua'
local MAX_ENTRIES = 5

local cache

local function load()
  if cache then return cache end
  local data = Save.loadLua(FILENAME, { highScores = {} })
  cache = data
  return cache
end

local function sortAndTrim()
  table.sort(cache.highScores, function(a,b) return a.score > b.score end)
  while #cache.highScores > MAX_ENTRIES do table.remove(cache.highScores) end
end

function Highscores.submit(score)
  if not score or score <= 0 then return end
  local data = load()
  table.insert(data.highScores, { score = score, dateIso = os.date('!%Y-%m-%d') })
  sortAndTrim()
  Save.saveLua(FILENAME, data)
end

function Highscores.list()
  local data = load()
  sortAndTrim()
  return data.highScores
end

return Highscores
