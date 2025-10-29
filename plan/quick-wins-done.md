# Quick Wins Plan

## 1. Add .luacheckrc
- Create `.luacheckrc` in root with: `ignore = {'love'}`
- Run `luacheck src/` to verify warnings suppressed.
- Add to AGENTS.md: Lint: `luacheck src/`
- Integrate to CI: Add step in `.github/workflows/love-android.yml` (or new workflow).

## 2. Expand README
- Add sections: "Quick Start" (`love .`), "Gameplay" (describe controls/objectives), "Architecture" (state diagram: title -> play -> pause/gameover), "Contributing" (fork, PRs, run tests/lint).
- Include screenshots: Add `docs/screenshots/` with images of title/play/gameover.
- Update build section: Mention web export explicitly.
- Keep concise (~200 lines total).

## 3. Extract Constants
- Create `src/config/constants.lua`: Export tables for COLORS (from main.lua), speeds (e.g., BULLET_SPEED=320), wave params (from waves.lua).
- Refactor: Replace magic numbers (e.g., in player.lua: `local BULLET_SPEED = require('src.config.constants').BULLET_SPEED`).
- Update modules: Require and use in game/, ui/, fx/ files.
- Test: Run `love .` to ensure no breakage.