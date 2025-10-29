local busted = require('busted')
local Waves = require('src.game.waves')

describe('Waves configuration', function()
  it('should return correct config for wave 1', function()
    local config = Waves.configFor(1)
    assert.are.equal(1, config.wave)
    assert.are.equal(60, config.formationSpeed)
    assert.are.equal(0.6, config.enemyFireRate)
    assert.are.equal(8, config.cols)
    assert.are.equal(1, config.rows)
    assert.is_false(config.boss)
  end)

  it('should increase speed with wave number', function()
    local config1 = Waves.configFor(1)
    local config2 = Waves.configFor(2)
    assert.is_true(config2.formationSpeed > config1.formationSpeed)
  end)

  it('should have boss waves every 5 waves', function()
    assert.is_false(Waves.configFor(1).boss)
    assert.is_false(Waves.configFor(4).boss)
    assert.is_true(Waves.configFor(5).boss)
    assert.is_false(Waves.configFor(6).boss)
  end)

  it('should limit columns and rows to maximum values', function()
    local config = Waves.configFor(20) -- Very high wave number
    assert.are.equal(12, config.cols) -- maxCols
    assert.are.equal(6, config.rows)   -- maxRows
  end)
end)

describe('Player module', function()
  local Player

  before_each(function()
    Player = require('src.game.player')
  end)

  it('should initialize with default values', function()
    Player.init(1280, 720)
    assert.are.equal(640, Player.x) -- center X
    assert.are.equal(656, Player.y) -- VIRTUAL_HEIGHT - 64
    assert.are.equal(360, Player.speed)
    assert.are.equal(4.0, Player.fireRate)
    assert.are.equal(3, Player.lives)
  end)

  it('should respect movement boundaries', function()
    Player.init(1280, 720)
    
    -- Test left boundary
    Player.x = 0
    Player.update(0.016, {moveAxis = -1}, function() end)
    assert.is_true(Player.x >= 44) -- margin + width/2
    
    -- Test right boundary  
    Player.x = 1280
    Player.update(0.016, {moveAxis = 1}, function() end)
    assert.is_true(Player.x <= 1236) -- VIRTUAL_WIDTH - margin - width/2
  end)

  it('should handle cooldown correctly', function()
    Player.init(1280, 720)
    local bullets = {}
    
    -- First shot should work
    Player.update(0.016, {firePressed = true}, function(x, y, dy, from, damage)
      table.insert(bullets, {x = x, y = y, dy = dy, from = from, damage = damage})
    end)
    assert.are.equal(1, #bullets)
    
    -- Immediate second shot should not work due to cooldown
    Player.update(0.016, {firePressed = true}, function(x, y, dy, from, damage)
      table.insert(bullets, {x = x, y = y, dy = dy, from = from, damage = damage})
    end)
    assert.are.equal(1, #bullets) -- Still only 1 bullet
  end)
end)