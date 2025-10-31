# Menu Leaderboard Integration Plan

## Objective
Move the existing post-run leaderboard into the main menu so players can browse local high scores any time (local storage only for now).

## Tasks
- Review current leaderboard data flow after death (likely handled in `src/ui/gameover.lua` or similar) and identify storage format/location.
- Refactor leaderboard state into a reusable module (`src/systems/highscores.lua` exists—reuse or extend) that exposes read/write APIs for the menu.
- Add a new Leaderboard screen accessible from the title menu:
  - Update `src/ui/title.lua` to include a “Leaderboard” option.
  - Create `src/ui/leaderboard.lua` (or extend existing module) for rendering entries with pagination and controller/touch navigation.
- Ensure entries display score, wave reached, and cosmetics/ship info if available.
- Add a “Clear Scores” option gated behind a confirmation (reuse settings reset flow if possible).
- Update layout to support various aspect ratios and ensure font caching work is leveraged.

## Risks & Mitigations
- **Data duplication:** centralize leaderboard reads so death screen and menu share the same component.
- **UI clutter:** prototype layout in Figma or whiteboard to keep menu flow clean; consider a dedicated sub-screen rather than overlay.

## Done When
- Title menu exposes a Leaderboard option that shows the top local scores without needing to die first.
- Death screen updates the same leaderboard and transitions back to the menu cleanly.
