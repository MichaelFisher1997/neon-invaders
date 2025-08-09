# Neon Invaders – TODO

Source of truth: `SPECS.md`. Keep items small, tick as delivered, and note changes.

## Milestone A: Foundations
- [x] Initialize Love2D project (`conf.lua`, `main.lua` boilerplate)
  - Notes: Set up LÖVE 11.x app, default filter to nearest.
- [x] Implement virtual resolution scaler + letterbox (`src/systems/scaling.lua`)
  - Notes: Canvas-based scaler with toVirtual/toScreen helpers; handles `love.resize`.
- [x] Starfield background (`src/fx/starfield.lua`)
  - Notes: Two-layer parallax stars; density scales with virtual area.
- [x] Input abstraction (`src/core/input.lua`) for keyboard + touch
  - Notes: Unified `moveAxis`, `firePressed`, `pausePressed`; touch zones & fire button (~15% width).

## Milestone B: Core Gameplay
- [x] Player system (move, shoot, cooldown, lives)
- [x] Bullet manager (player/enemy pools)
- [x] Alien grid (spawn, march, edge-step, speed ramp)
- [ ] Enemy fire logic (timers scaled by wave)
- [x] Enemy fire logic (timers scaled by wave)
- [x] Collision detection (bullets vs aliens & player)
- [x] Explosions (`fx/particles.lua`) and screen shake (`fx/screenshake.lua`)
- [x] Lose conditions (aliens bottom / lives 0)
  - [x] Player death -> explosion + respawn in middle with invincibility flash

## Milestone C: Meta & Progression
- [x] Wave manager (difficulty curve) with difficulty multipliers
- [ ] Boss entity (HP, pattern, hitbox) every 5 waves
- [x] Boss entity (HP, pattern, hitbox) every 5 waves — basic spread pattern
- [ ] Upgrade menu between waves (+move, +firerate, +life, +shield)
- [x] Upgrade menu between waves — basic 4-option selector; applies immediately

## Milestone D: UI/UX
- [x] Title screen (start prompt)
- [x] HUD (score, lives icons centered, wave)
- [x] Pause overlay (Resume/Restart/Quit)
- [x] Game Over (score, retry/quit)
- [x] Settings (music/sfx volume, difficulty) – basic shell
  - [x] Difficulty is a proper left/right selector
- [ ] Touch controls (left/right zones + fire button ~15% width)
  - [x] Subtle on-screen touch hints for zones/buttons

## Milestone E: Polish
- [ ] Particle bursts on kills; brief screen shake on player hit
  - [x] Initial particles and screen shake
- [ ] “Wave Cleared!” banner animation
  - [x] Basic banner on wave transition
- [ ] Cosmetic unlocks at score thresholds (ship color)
 - [x] Local high scores (`src/systems/save.lua`)
- [ ] Basic audio loader + volume persistence (`src/systems/settings.lua`)
  - [x] SFX beeps for shoot/hit/explosion/UI; simple music loop

## Milestone F: QA
- [ ] Test scaling on 720×1280, 1080×2400, 1440×3120
- [ ] Verify touch hitboxes, HUD margins, and pause overlay on all sizes
- [ ] Validate performance (no GC spikes; pooled bullets/particles)

---

## Changelog
- [A] Foundations delivered: scaffolding, virtual scaler, starfield, input abstraction.
- [B] Minimal playable loop: player move/shoot, single-row aliens marching/edge-step, bullet pooling, collisions, wave progression; basic Title/Play/Pause/Game Over flow with HUD.
- [B+] Enemy bullets and player lives; explosions and screen shake integrated.
- [D] Settings screen shell with volume sliders and difficulty; local settings persistence.
- [C] Wave manager with difficulty-aware curves; applied extra life on Easy; added wave-cleared banner.
- [E] Local high scores (top 5) with auto-submit and display on Game Over.
- [E] Audio: synthesized SFX and simple looping music; wired to settings volumes.
