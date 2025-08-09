# Neon Invaders – Agent Operating Guide

## Goals
- Deliver a premium-feel, small-scope arcade shooter per `SPECS.md`.
- Prioritize core gameplay and readability. Desktop runs first, then mobile.

## Decision Rules
- Always update `SPECS.md` first if mechanics or parameters change.
- Update `TODO.md` alongside code changes; tick items as completed and add a brief changelog line.
- De-scope first if blocked > 20 minutes: drop cosmetic extras or reduce parameters; document the decision in this file.
- Keep deterministic update order: input → logic → collisions → effects → UI.

## Commit Style
- Concise, why-focused messages. Example: "implement virtual scaling for 1280×720 and letterboxing"
- Group related changes per commit. No unrelated refactors.

## Testing Procedure
1. Desktop test first (Love2D): verify scaling on window resizes; check starfield, input overlays if debug.
2. Keyboard controls: arrows/A-D move; space fires (when implemented); esc pauses.
3. Simulate mobile by resizing window narrow/tall; verify touch zones scale; later test on Android build.
4. Performance: ensure no GC spikes; verify pools for bullets/particles.

## Scope Discipline
- Modules are focused, ≤ ~50 lines per function when reasonable. No god files.
- Avoid magic numbers; constants at top of modules and/or in `SPECS.md`.
- Time-based movement using `dt`.

## Update Mechanics
- After implementing a unit:
  - Tick the corresponding item(s) in `TODO.md`
  - Add a one-line note in Changelog
  - If behavior changed, adjust `SPECS.md`

## De-scope First Rule
When blocked:
- Prefer removing polish over features; preserve acceptance criteria.
- Examples: reduce star layers, simplify boss pattern, skip cosmetic unlock animations.
- Document what and why here; revisit later if time permits.
