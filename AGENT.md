# Neon Invaders – Agent Operating Guide

## Build Commands
- **Desktop**: Run `love .` (requires LÖVE 11.x)
- **Android Debug**: `bash scripts/build-android-debug.sh`
- **Web Export**: `bash scripts/export-web-lovejs.sh --serve`
- **Test**: Manual testing via desktop Love2D; no automated test framework

## Code Style Guidelines
- **Imports**: Use `local Module = require("src.path.module")` at file top
- **Naming**: PascalCase for modules, camelCase for functions/variables, UPPER_SNAKE for constants
- **Structure**: Modular design, ≤50 lines per function, single responsibility
- **Data**: Time-based movement with `dt`, pooled objects for performance
- **Constants**: Define at module top or reference `SPECS.md` values
- **Error Handling**: Simple returns, avoid complex exception hierarchies

## Development Rules
- Update `SPECS.md` first when mechanics change
- Deterministic update order: input → logic → collisions → effects → UI
- Test desktop first, then mobile via window resize simulation
- De-scope polish over features when blocked >20 minutes
- Group related changes per commit with concise, why-focused messages

## Virtual Resolution
- Target: 1280×720 with letterbox/pillarbox scaling
- Three-panel layout: 20% left (controls), 60% center (game), 20% right (controls)
- All coordinates in virtual space via scaling system helpers
