local Config = {}

-- Adjustable cosmetic unlock thresholds and styles
-- You can reorder, rename, and tweak thresholds/colors freely.
Config.cosmetics = {
  -- Start default is White (not listed here; selecting none keeps you white)
  { id = "red",      name = "Red",        threshold = 1000,  color = {1.0, 0.25, 0.25, 1.0} },
  { id = "green",    name = "Green",      threshold = 3000,  color = {0.20, 1.00, 0.35, 1.0} },
  { id = "blue",     name = "Blue",       threshold = 6000,  color = {0.30, 0.55, 1.00, 1.0} },
  { id = "rgb_trip", name = "RGB Trip",   threshold = 10000, color = {1.0, 1.0, 1.0, 1.0} }, -- dynamic color
}

return Config
