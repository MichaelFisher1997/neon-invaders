# Boss System Overhaul Plan

## Overview
Replace the single purple rectangle boss with a diverse collection of unique boss types that provide varied challenges and gameplay experiences.

## Boss Selection System

### Implementation Strategy
- **Rotation Pattern**: Cycle through boss types every boss wave (every 5 waves)
- **Boss ID Calculation**: `bossTypeIndex = (wave // 5) % totalBossTypes`
- **Progressive Difficulty**: Earlier bosses are simpler, later waves introduce more complex mechanics
- **Shared Interface**: All bosses implement the same API for seamless integration

### Boss Types & Progression

#### Wave 5-9: **Shield Boss**
- **Design Goal**: Teach players to break through defenses
- **Health**: Base formula * 0.8 (easier entry boss)
- **Mechanics**: 3 shield segments protect core, break from bullets
- **Attack**: Slow spread shots when shields down
- **Visual**: Large purple boss with 3 glowing shield segments

#### Wave 10-14: **Diving Boss**
- **Design Goal**: Introduce movement-based challenge
- **Health**: Base formula
- **Mechanics**: Horizontal movement + periodic dive attacks
- **Attack**: Bomb drops during dives, fast shots when at top
- **Visual**: Red/orange with diving trail effects

#### Wave 15-19: **Splitter Boss**
- **Design Goal**: Multiple target management
- **Health**: Base formula * 1.2
- **Mechanics**: Splits into 2-3 segments when damaged
- **Attack**: Each segment fires different patterns
- **Visual**: Green composite boss that fragments

#### Wave 20-24: **Laser Boss**
- **Design Goal**: Precise timing and positioning
- **Health**: Base formula * 1.4
- **Mechanics**: Charges laser sweeps across screen
- **Attack**: Sweeping laser beams, mini-bursts when charging
- **Visual**: Blue/cyan with charge-up glow effects

#### Wave 25-29: **Summoner Boss**
- **Design Goal**: Crowd control and prioritization
- **Health**: Base formula * 1.6
- **Mechanics**: Spawns mini-enemies periodically
- **Attack**: Indirect via summoned minions
- **Visual**: Dark purple with summoning particle effects

#### Wave 30-34: **Phase Boss**
- **Design Goal**: Pattern recognition and timing
- **Health**: Base formula * 1.8
- **Mechanics**: Cycles between vulnerable/invulnerable states
- **Attack**: Different patterns per phase
- **Visual**: Shifting colors, ghost-like transparency effects

#### Wave 35-39: **Turret Boss**
- **Design Goal**: 360-degree threat management
- **Health**: Base formula * 2.0
- **Mechanics**: Central core with 4 rotating turrets
- **Attack**: Independent turret firing patterns
- **Visual**: Metal gray with rotating barrel indicators

#### Wave 40+: **Minesweeper Boss**
- **Design Goal**: Spatial awareness and planning
- **Health**: Base formula * 2.5
- **Mechanics**: Erratic movement + proximity mines
- **Attack**: Lays explosive mines with timer detonation
- **Visual**: Orange/yellow with mine-dropping animations

## Technical Implementation

### File Structure
```
src/game/boss/
├── base.lua           # Shared boss framework
├── shield.lua         # Shield boss implementation
├── diving.lua         # Diving boss implementation
├── splitter.lua       # Splitter boss implementation
├── laser.lua          # Laser boss implementation
├── summoner.lua       # Summoner boss implementation
├── phase.lua          # Phase boss implementation
├── turret.lua         # Turret boss implementation
└── minesweeper.lua    # Minesweeper boss implementation
```

### Shared Boss API
```lua
local Boss = require("src.game.boss.base")

-- Each boss module exports functions:
function Boss.spawnFromConfig(cfg, vw, vh)  -- Initialize boss
function Boss.exists()                        -- Check if boss alive
function Boss.update(dt)                      -- Update boss logic
function Boss.draw()                          -- Render boss
function Boss.hit(dmg)                        -- Apply damage
function Boss.aabb()                          -- Get collision box
function Boss.getMinions()                    -- Get spawned minions (if any)
function Boss.cleanup()                       -- Clean up resources
```

### Boss Manager Integration
- Modify existing `Boss.spawnFromConfig()` to select boss type
- Update `Boss.update()` to call correct boss-specific logic
- Maintain backwards compatibility with existing game code

### Mini-Boss System (Summoner Boss)
- Create `src/game/boss/minion.lua` for summoned enemies
- Minions have simple AI and limited lifespan
- Minion spawn/die events integrate with existing particle system

### Visual Enhancement Plan
- **Color Coding**: Each boss type has distinctive colors
- **Particle Effects**: Death animations, movement trails, attack effects
- **UI Enhancements**: Boss-specific health bars, special status indicators
- **Sound Design**: Unique audio cues per boss type (if audio system supports)

### Difficulty Balancing
- **Early Bosses**: 80-100% of base health (easier learning curve)
- **Mid Bosses**: 120-160% of base health
- **Late Bosses**: 180-250% of base health (serious challenge)
- **Credit Rewards**: Scale with difficulty multiplier

## Implementation Phases

### Phase 1: Framework (1-2 hours)
1. Create boss directory structure
2. Implement shared boss base class
3. Add boss selection logic
4. Update existing boss manager integration

### Phase 2: Core Bosses (3-4 hours)
1. Shield Boss - Basic multi-phase combat
2. Diving Boss - Movement pattern variation
3. Splitter Boss - Multiple target management

### Phase 3: Advanced Bosses (4-5 hours)
1. Laser Boss - Timing-based combat
2. Phase Boss - State machine patterns
3. Summoner Boss - Minion management system

### Phase 4: Expert Bosses (3-4 hours)
1. Turret Boss - 360-degree threats
2. Minesweeper Boss - Spatial puzzle combat

### Phase 5: Polish (1-2 hours)
1. Visual effects and particle systems
2. Sound integration (if supported)
3. Difficulty fine-tuning
4. Performance optimization

## Testing Strategy
- **Progressive Testing**: Test each boss type individually before integration
- **Balance Testing**: Verify difficulty progression feels natural
- **Performance Testing**: Ensure multiple bosses don't impact framerate
- **Integration Testing**: Verify bosses work with existing wave/upgrade systems

## Success Metrics
- Each boss type provides unique challenge requiring different strategies
- Player progression through boss waves feels rewarding, not frustrating
- Visual and mechanical variety maintains engagement over long play sessions
- Technical implementation maintains 60fps performance
- Boss system integrates seamlessly with existing economy/upgrade progression