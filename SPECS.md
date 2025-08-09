# Neon Invaders – Formal Specification (v1.0)

## 1. Overview
Neon Invaders is a premium, small-scope, retro arcade shooter inspired by Space Invaders. The player controls a ship at the bottom of the screen, moving left/right and firing upwards at a marching formation of aliens. Endless waves increase difficulty, with a boss every 5 waves and a single between-wave upgrade choice. The look is a clean neon palette on black, with juicy feedback (particles, subtle screen shake), offline play, and no ads.

- Engine: LÖVE (Love2D) 11.x, Lua
- Primary platform: Android; Secondary: Desktop
- Rendering: 2D, vector/pixel primitives (no external assets required)
- Virtual resolution: 1280×720 (16:9). Letterbox/pillarbox scaling to device.
- Input: Touch (mobile) + Keyboard (desktop)

## 2. Design Pillars
- Fast, readable, responsive gameplay with deterministic update order: input → logic → collisions → effects → UI
- Minimalist neon aesthetic: cyan/magenta/purple/white on nearly-black
- Small but polished feature set; de-scope fancy bits first when blocked
- Tight scope; code clarity; modules are focused; helpers are pure where possible

## 3. Virtual Resolution & Scaling
- Target virtual size: 1280×720. Game logic, UI layout, and touch hitboxes computed in virtual space.
- Device scaling: render to a virtual canvas, then scale uniformly to fit device; center with letterboxing (black bars). Maintain aspect ratio.
- Coordinate conversion helpers:
  - toVirtual(x_screen, y_screen) → (x_virtual, y_virtual)
  - toScreen(x_virtual, y_virtual) → (x_screen, y_screen)
- HUD/touch layout use percentages of the virtual resolution.

## 4. Game States (State Machine)
- Title: Logo, Start, Settings, Quit; animated starfield background.
- Playing: Core loop. Sub-states:
  - Active Wave
  - Wave Cleared Banner
  - Intermission Upgrade (one choice)
- Paused: Dim overlay; Resume/Restart/Quit.
- Game Over: Final score; Retry/Quit.
- Settings: Music volume, SFX volume, Difficulty (Easy/Normal/Hard).

All states follow deterministic update order. Transitions are explicit and validated.

## 5. Data Shapes
Types are written informally; all coordinates in virtual units unless noted.

- Settings
  - musicVolume: number [0..1]
  - sfxVolume: number [0..1]
  - difficulty: 'easy' | 'normal' | 'hard'

- SaveData
  - highScores: array of { score: integer, dateIso: string }
  - unlockedCosmetics: { shipColor: string | nil }

- InputState (per frame)
  - moveAxis: number in [-1, 1]
  - firePressed: boolean (edge)
  - fireHeld: boolean
  - pausePressed: boolean (edge)

- Player
  - x: number (center)
  - y: number (baseline near bottom)
  - speed: number (pixels/sec)
  - width, height: numbers
  - cooldown: number (seconds, current)
  - fireRate: number (shots/sec)
  - lives: integer
  - shieldTimer: number (seconds remaining, 0 if none)
  - color: { r,g,b,a }

- Bullet
  - x, y: numbers (center)
  - dy: number (speed y, +/-)
  - from: 'player' | 'enemy' | 'boss'
  - active: boolean
  - radius: number
  - damage: number

- Alien
  - x, y: numbers (grid-local offset applied to formation origin)
  - alive: boolean
  - type: 'basic' | 'elite' (for future; v1 mostly 'basic')
  - scoreValue: integer

- AlienFormation
  - originX, originY: numbers (top-left of formation)
  - dir: 1 or -1 (horizontal direction)
  - speed: number (px/sec)
  - stepDown: number (px to move down on edge)
  - cols, rows: integers
  - aliens: Alien[][]
  - bounds: { left, right, top, bottom } (computed)

- Boss
  - x, y: numbers
  - width, height: numbers (larger hitbox)
  - hp, hpMax: integers
  - patternTimer: number
  - pattern: 'spread' | 'burst' | 'stream'
  - fireCooldown: number

- WaveConfig
  - waveIndex: integer (1..∞)
  - alienRows: integer
  - alienCols: integer
  - formationSpeed: number
  - enemyFireRate: number (shots/sec per formation)
  - stepDown: number
  - boss: boolean (waves multiple of 5)

- FX
  - Particle: { x,y, dx,dy, life, color, size }
  - ScreenShake: { t: seconds, strength: number }

- HUD
  - score: integer
  - lives: integer
  - wave: integer

## 6. Difficulty & Progression
- Base parameters (Normal difficulty unless stated):
  - Initial formation speed: 60 px/s
  - Step-down per edge: 24 px
  - Enemy fire base: 0.6 shots/sec (formation-level probability)
  - Player: speed 360 px/s, fireRate 4.0 shots/sec, lives 3
- Ramps by wave (w = 1-based):
  - formationSpeed(w) = 60 + 10 * (w - 1)
  - enemyFireRate(w) = 0.6 + 0.08 * (w - 1)
  - cols/rows: start 8×3, add +1 col every 2 waves (cap 12), +1 row every 3 waves (cap 6)
  - stepDown: constant 24 (may +4 on Hard)
- Boss every 5th wave:
  - hpMax(w) = 20 + 8 * floor(w/5)
  - pattern rotates between 'spread', 'burst', 'stream'
  - fireRateBoss(w) = 1.2 + 0.2 * floor(w/5)
- Difficulty multipliers:
  - Easy: formationSpeed ×0.9, enemyFire ×0.8, player lives +1
  - Normal: ×1.0
  - Hard: formationSpeed ×1.15, enemyFire ×1.25, stepDown +4, player shield upgrade duration −20%

## 7. Collisions & Lose Conditions
- Bullet vs alien/boss: circle-rect or rect-rect simplified; deactivate bullet; spawn particles; add score.
- Enemy bullet vs player: if shieldTimer <= 0 then player loses life; brief screen shake.
- Lose when:
  - player lives ≤ 0, or
  - alien formation bottom ≥ player y − margin

## 8. Between-wave Upgrade (one choice)
- Options (values pre-upgrade):
  - +Move Speed: +15% speed (stacking multiplicative)
  - +Fire Rate: +15% fireRate (cap 12 shots/sec)
  - +1 Life: +1 up to max 6
  - Short Shield: shieldTimer = max(shieldTimer, 8s)
- Choice UI: three cards centered; tap/click to select; applies immediately for next wave.

## 9. UI/UX Layout
- Title
  - Logo text centered top third; buttons stacked with 2% vertical spacing.
- HUD
  - Score top-left: margin 2% of width/height
  - Lives centered top: small ship icons spaced 32 px virtual
  - Wave top-right: margin 2%
- Pause Overlay
  - Dim rectangle (black with 50% alpha), menu centered.
- Game Over
  - Final score large at center; Retry/Quit buttons below.
- Settings
  - Sliders for Music/SFX volumes; Difficulty radio buttons.
- Touch Controls (virtual-relative)
  - Left zone: 0%–35% width, full height
  - Right zone: 35%–70% width, full height
  - Fire button: bottom-right; diameter ≈ 15% of screen width; margin 3%

## 10. Visual Style
- Palette (RGBA in hex):
  - Background: #0a0a0f
  - Cyan: #27f3ff
  - Magenta: #ff2ea6
  - Purple: #8a2be2
  - White: #ffffff
- Effects: subtle 6–12 px screen shake on hits; particle bursts on kills.

## 11. Audio
- SFX events → ids
  - ui_click → sfx/ui_click
  - player_shoot → sfx/player_shoot
  - enemy_shoot → sfx/enemy_shoot
  - hit → sfx/hit
  - explosion → sfx/explosion
  - wave_cleared → sfx/wave_cleared
  - boss_entrance → sfx/boss_entrance
- Music
  - Single looping chiptune track 'music/loop'
- Volume control
  - Master music and sfx volumes [0..1] applied to all sources; persisted.

## 12. Acceptance Criteria (v1.0)
- Runs in Love2D desktop; scales correctly with letterboxing on window resize.
- Title → Start → Play → Pause → Game Over flows work.
- Player can move, fire; aliens march and step down; bullets collide; lives & score update.
- Waves ramp; boss spawns on wave 5 with extra HP & pattern.
- Between-wave upgrade prompt appears and applies effect.
- HUD always readable; touch controls scale on simulated small/large resolutions.
- SFX for shoot/hit/explosion/UI; music loop togglable; volume sliders work.
- Local high score list updates after Game Over.

## 13. Implementation Notes
- Update order per frame: input.update → game.update → collisions.resolve → fx.update → ui.update
- Pooled bullets and particles to avoid GC spikes.
- Modules are small and single-purpose; most helpers are pure.

## 14. Source of Truth
This document is the authoritative spec. If a mechanic changes during development, update this spec first, then implement.
