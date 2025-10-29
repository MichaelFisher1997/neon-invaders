# Future-Proofing Plan

## 1. Dependency Injection
- Create services table in main.lua: e.g., `services = {audio = require('src.audio.audio'), scaling = require('src.systems.scaling')}`
- Pass to modules: e.g., `Game.init(services.scaling.getVirtualSize(), services.audio)`
- Update requires: Remove globals; use passed params/callbacks.
- Benefits: Easier mocking in tests; swap impls (e.g., mock audio).

## 2. ECS Pattern
- If expanding: Add tiny-ecs (Lua lib) or simple impl in `src/ecs/`.
- Entities: Player/Aliens as components (position, velocity, render).
- Systems: UpdateSystem(dt, entities), CollisionSystem(entities).
- Migrate gradually: Start with bullets/particles.
- Defer unless >50 entities.

## 3. Web Polish
- Create `scripts/export-web.sh`: `love . --fused --export-type=web --output=web-build`
- Test: Serve with `python -m http.server` or script/serve-web.py; check touch/controls.
- Optimize: Minify Lua (luamin); compress assets.
- Docs: Add to README: "Web: Run export script, open index.html".

## 4. Metrics
- Add debug overlay in main.lua: If F2 pressed, draw FPS (`love.timer.getFPS()`) and entity counts (e.g., #active bullets).
- Profile: Use LÖVE's `love.profiler` in update/draw; log bottlenecks.
- Integrate: Toggle via settings; no perf hit in release.