# Credit Multiplier Persistence Plan

## Objective
Ensure wave-based credit multipliers survive restarts so late-game runs keep their progression momentum.

## Tasks
- Audit `src/systems/economy.lua` save/load logic and extend the serialized state with `creditMultiplier`, `currentWave`, and `creditMilestoneWave`.
- Add safe defaults/migration path so legacy economy saves upgrade cleanly.
- Update `Economy.reset()` to clear the new fields and delete stale saves.
- Exercise new persistence path by simulating: run to wave 60, award credits, reload, and confirm multiplier resumes at `x2`.
- Add busted spec covering serialization/deserialization of the economy state.

## Risks & Mitigations
- **Corrupting old saves:** gate new fields with `or` fallbacks and version bump if needed.
- **Multiplier desync on load:** add assertion in `Game.init` to re-call `Economy.updateCreditMultiplier` with loaded wave value to re-sync runtime state.

## Done When
- Reloading the game after reaching a milestone keeps the multiplier and milestones accurate.
- Tests and manual checklist confirm no regressions in credit accrual or spending.
