# Quality Boost Plan

## 1. Introduce Unit Tests
- Install busted: `luarocks install busted` (add to flake.nix if Nix env).
- Create `spec/` dir: e.g., `spec/game_spec.lua` for collisions/upgrades.
- Examples:
  - Test wave config: `describe('Waves', function() it('configFor(1) returns easy', function() assert.equal(3, Waves.configFor(1).playerLives) end) end)`
  - Test collisions: Mock AABB funcs, assert hits/deaths.
- Run: `busted spec/` (all), `busted spec/game_spec.lua` (single).
- Integrate: Add to AGENTS.md; run in CI after lint.

## 2. Refactor Input
- Enhance `src/core/input.lua`: Add unified handlers (e.g., `handlePointer(x, y, type)` for key/mouse/touch).
- Move logic from main.lua: e.g., title/gameover presses -> call `input.handleUI(state, x, y)`.
- Reduce duplication: Merge touch/mouse in one func; use events table.
- Test: Simulate inputs in tests; playtest on desktop/mobile.

## 3. Add Comments
- Use LuaDoc: `@param dt number @return void` on public funcs (e.g., Game.update).
- Explain complexity: Wave progression in game.lua (boss/intermission flow).
- Inline: Key assumptions (e.g., "Assumes center panel for gameplay").
- Tools: Run `luadoc src/` if installed; keep <20% code coverage.