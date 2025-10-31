# Special Alien Reward Audit Plan

## Objective
Decide whether current credit payouts for special aliens (flat bonus + dedicated award) are intentional and rebalance if necessary.

## Tasks
- Document existing credit flow in `Game.update` for alien kills and compare with `Economy.awardSpecialAlienKill()`.
- Run quick instrumentation or logging to verify real credit deltas for each alien variant across waves and multipliers.
- Meet with design/product to confirm intended reward structure (single vs double bonus, multiplier behavior).
- If double bonus is unintended, adjust code to grant either the flat bump or the explicit award, not both.
- Rebalance `specialAlienBonus` in `Constants.ECONOMY` based on desired pacing and multiplier stack.
- Update unit test (or add new busted spec) covering alien reward expectations under `x1` and `x2` multipliers.

## Risks & Mitigations
- **Economy swing:** use spreadsheets or simulation to project credit flow before/after changes.
- **Player perception:** communicate any nerf in patch notes, or offset with cosmetic unlock pricing tweaks.

## Done When
- Reward policy is finalized, code reflects the decision, and regression tests prove the expected credit totals.
