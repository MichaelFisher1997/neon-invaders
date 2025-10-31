# Publish Readiness Checklist

## Goal
Ship a polished, stable build on PC/mobile/web storefronts with clear marketing and support plans.

## Gameplay & UX
- Complete end-to-end playtests across waves 1–150, logging difficulty spikes and credit pacing.
- Polish HUD and menus for controller, mouse, and touch; add settings for audio, screen shake, colorblind modes.
- Validate tutorial/onboarding covers cosmetics, upgrades, and credit bonuses.

## Technical
- Ensure deterministic saves across desktop/mobile; confirm economy data persists and survives version upgrades.
- Profile performance on low-end hardware (target 60 FPS); optimize draw calls, particles, and audio loads.
- Build automation: scripts for Windows/macOS/Linux, Android APK, and web export; smoke-test each artifact.
- Implement crash/error telemetry (e.g., Sentry) and basic analytics hooks (wave reached, credits earned, shop visits).

## QA & Testing
- Finalize automated test suite (luacheck + busted) and add manual regression checklist per platform.
- Conduct beta with external testers; collect bug reports via structured form.
- Verify localization readiness (string tables) even if only English at launch.

## Content & Live Ops
- Lock launch content scope (bosses, cosmetics, shop inventory).
- Prepare roadmap for post-launch updates (new waves, cosmetic drops, events).
- Set up community channels (Discord, Steam forums) with moderation guidelines.

## Marketing & Business
- Produce trailer, screenshots, key art, store copy, and press kit.
- Decide launch pricing or F2P model; align with monetization roadmap.
- Coordinate soft launch/early access plan to gather metrics before full release.

## Support
- Create FAQ/support docs; set up email or ticketing system.
- Plan day-one patch readiness with hotfix pipeline.
- Document rollback procedure for corrupted saves or exploit fixes.

## Done When
- All checklist items have owners, due dates, and sign-offs, and the build passes beta testing without blocker issues.
