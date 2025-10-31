# Automated Testing Rollout Plan

## Objective
Establish a reliable busted/luacheck CI pipeline and expand coverage for wave progression, saving, and credit systems.

## Tasks
- Set up `luacheck` locally and in CI (GitHub Actions or similar) with project-specific configuration updates.
- Restore or create busted specs covering:
  - Wave advancement and `setWave` credit multiplier sync.
  - Economy save/load round-trip with multipliers and upgrades.
  - Alien reward credit totals for base and special variants.
- Add smoke tests for initialization and basic rendering via headless LÖVE (if feasible) or mock love modules.
- Integrate test commands into build scripts (`README`, `AGENTS.md`) and enforce via pre-commit hook.
- Track coverage gaps and plan incremental spec additions per subsystem (player, bosses, events).

## Risks & Mitigations
- **Love API mocking complexity:** leverage existing test helpers or build a stub layer to simulate `love.graphics`.
- **CI environment limitations:** use xvfb or the headless `love` binary for automated runs; fall back to pure Lua tests when necessary.

## Done When
- `luacheck` and `busted` run cleanly both locally and in CI, and critical core systems have regression coverage.
