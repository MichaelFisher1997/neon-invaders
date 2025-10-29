# AGENTS.md

## Build Commands
- Run game locally: `love .` (requires LÖVE 11.5 installed)
- Android debug APK: `bash android/bootstrap-android.sh && cd android && ./gradlew assembleDebug`
- Android release APK: Set up keystore.properties, then `cd android && ./gradlew assembleRelease`
- Web export: `love . --fused --export-type=web` or use scripts/export-web-lovejs.sh if available

## Lint and Test Commands
- Run all tests: `busted spec/` (unit tests using busted framework)
- Run single test: `busted spec/game_spec.lua` (specific test file)
- Lint: `luacheck src/` (standard Lua linter; .luacheckrc configured to ignore love global)
- Format: `stylua src/` (assumes stylua installed; no .stylua.toml, uses defaults)

## Code Style Guidelines
- Language: Lua 5.1 (LÖVE 2D 11.x); avoid Lua 5.2+ features.
- Imports: Use `local Module = require("src.path.module")` at file top; relative paths from src/.
- Formatting: 2-space indentation; no semicolons; line length ~100 chars; no trailing whitespace.
- Naming: camelCase for variables/functions (e.g., `playerX`); PascalCase for modules/tables (e.g., `Player`).
- Types: Dynamic; use tables for objects; document with comments if complex.
- Error Handling: Wrap risky calls in `pcall`; use `love.errorhandler` for globals; print errors for debugging.
- Conventions: Follow LÖVE callbacks (love.load, love.update(dt)); modularize in src/ (systems/, game/, ui/, etc.).
- No Cursor/Copilot rules found (.cursor/ or .github/copilot-instructions.md absent).

Follow existing patterns in main.lua and src/game/game.lua for consistency.