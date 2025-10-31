# Font Caching Optimization Plan

## Objective
Eliminate per-frame font allocations in HUD and upgrade UI to avoid needless CPU/GPU churn.

## Tasks
- Inventory all `love.graphics.newFont` calls inside draw loops (HUD, upgrade menu, cosmetics, etc.).
- Introduce a shared `ui/fonts.lua` helper that loads fonts on demand and caches them by size/weight.
- Refactor HUD (`src/ui/hud.lua`) and upgrade menu (`src/ui/upgrademenu.lua`) to reuse cached font instances.
- Add defensive asserts to ensure no remaining `newFont` calls appear inside render paths (e.g., static analyzer script).
- Profile draw call time before/after to quantify savings on low-end hardware.

## Risks & Mitigations
- **Font reference leaks:** centralize cache lifetime to match game lifetime; expose `Fonts.reset()` for hot reloads.
- **Style regressions:** verify kerning/line-height visually after font substitution.

## Done When
- No `newFont` calls occur inside per-frame code, and FPS profiling shows stable render times with identical visuals.
