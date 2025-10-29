# Neon Invaders Overhaul Plan

## Overview
This plan overhauls the game to make it a polished, marketable arcade shooter with 30-60 min replayability. Focus: Enhance core loop (variety, progression), add modes/unlocks, improve polish (UI/audio/visuals). Phased approach: Short (1-2 weeks, core fixes), Medium (2-4 weeks, depth), Long (2-4 weeks, expansion). Total: 1-3 months solo dev time. Test iteratively with `love .`; add to AGENTS.md for commands.

Prioritize: Fun > Features > Polish. Defer monetization (ads/IAP) until v1.0 ready.

## Phase 1: Core Loop Polish (1-2 Weeks)
Fix basics for engaging play; aim for 20-min sessions without frustration.

### 1.1 Input & Controls
- Centralize in `src/core/input.lua`: Unified handler for key/mouse/touch (e.g., `handleInput(type, x, y, dt)`).
- Add swipe shooting (mobile: drag to aim/fire); auto-fire toggle in settings.
- Tutorial: Overlay on first play (e.g., "Move with arrows/touch, shoot auto").
- Test: Playtest on desktop/Android; add debug mode (F1 for touch viz).

### 1.2 Gameplay Variety
- Enemy Types: In `src/game/aliens.lua`, add 3 variants (basic, diver—drops down; bomber—shoots bombs). Randomize per wave.
- Power-Ups: New module `src/game/powerups.lua`—drop from aliens (triple shot, shield, speed boost; last 10s). Spawn 10% chance.
- Mid-Wave Action: Aliens pause briefly on power-up drop; player collect by overlap.

### 1.3 Balance & Feedback
- Wave Tweaks: In `src/game/waves.lua`, add 5 more configs (e.g., wave 11+ faster). Grace period after boss.
- FX/Audio: Animate explosions (frame-based in `src/fx/particles.lua`); add power-up sound in `src/audio/audio.lua`.
- HUD: Show power-up timer; lives as hearts (visual in `src/ui/hud.lua`).

**Milestone**: Playable demo with varied waves; no crashes. Run lint/tests.

## Phase 2: Progression & Modes (2-4 Weeks)
Add depth for replayability; introduce hooks like unlocks.

### 2.1 Modes
- Endless Mode: In `src/game/game.lua`, after wave 10: Infinite scaling difficulty (speed +1%/wave). High score based on survival time.
- Campaign Mode: Simple story—5 chapters (banner text: "Defend Sector 1"); unlock via wave clears. Add in title menu.
- Difficulty: Expand settings (easy/medium/hard/normal); hard: Fewer lives, faster enemies.

### 2.2 Unlocks & Achievements
- Cosmetics Expansion: In `src/systems/cosmetics.lua`, add 10+ items (ships, trails, backgrounds). Unlock at score milestones (e.g., 5000 pts = cyan ship).
- Achievements: New `src/systems/achievements.lua`—local saves (e.g., "Pacifist: Clear wave 5 without shooting"). Display in cosmetics menu.
- Upgrades: Randomize intermission choices (3 options/wave); persistent across runs via saves.

### 2.3 UI/States
- Menus: Animate transitions (fade in `src/ui/title.lua`); add mode select in title.
- Gameover: Show stats (kills, accuracy); "Continue?" with rewarded life (placeholder for ads).
- Pause: Full anytime pause; quick resume.

**Milestone**: Multiple modes; 30-min playthrough. Beta test with friends (share APK).

## Phase 3: Visual/Audio Polish & Expansion (2-4 Weeks)
Elevate to "premium feel"; prepare for stores.

### 3.1 Visuals
- Sprites/Animations: Replace placeholders—add ship thrust, alien wobble, bullet trails (use free OpenGameArt assets; integrate via `love.graphics`).
- Background: Dynamic starfield variants (e.g., nebula in boss waves via `src/fx/starfield.lua`).
- Particles: More effects (e.g., shield glow, explosion variants).

### 3.2 Audio
- Tracks: 4-5 loops (menu, waves, boss, gameover) in `src/audio/audio.lua`; volume sliders work.
- SFX: Layered sounds (e.g., multi-hit boss); synth improvements for variety.

### 3.3 Technical/Accessibility
- Performance: Add FPS counter (toggle F2); optimize loops (e.g., pool more entities).
- Accessibility: Color-blind modes (grayscale toggle); larger touch targets; subtitles for banners.
- Platforms: Full web test (export script); iOS via love-ios if expanding.
- Tests: Add 10+ busted tests (e.g., collision, wave gen); run in CI.

### 3.4 Marketing Prep
- Assets: Screenshots (title/play/gameover), GIFs (gameplay loop), trailer (record with OBS).
- README: Update with modes, controls, screenshots; add "Download" links.

**Milestone**: v1.0 release—itch.io upload, Android APK. Gather feedback for v1.1.

## Risks & Tips
- Scope Creep: Stick to phases; prototype in branch (e.g., `git checkout -b overhaul-phase1`).
- Tools: Use Aseprite (free) for sprites; Audacity for audio.
- Time: 10-20 hrs/week; track in TODO.md.
- Next: After v1.0, revisit monetization (free + ads/IAP).

This turns prototype into product—fun, replayable, shareable.