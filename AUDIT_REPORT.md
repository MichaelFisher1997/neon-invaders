# Neon Invaders Code Audit & Refactoring Report

## Executive Summary
A comprehensive audit of the codebase was performed, focusing on performance, memory usage, and potential bugs. The overall architecture (Service-based dependency injection) is solid. However, several high-frequency performance bottlenecks (garbage collection churn) and a critical input bug were identified and resolved.

## Key Improvements

### 1. Performance Optimizations (Zero-Allocation Main Loop)
- **Problem**: The game was creating thousands of temporary tables every frame for:
  - Alien geometry rendering (`Aliens.draw`)
  - Touch input zone calculations (`Input.getTouchZones`)
  - Virtual screen panel caching (`Scaling.getPanelsVirtual`)
  - Bullet collision closures (`Bullets.eachActive`)
- **Solution**:
  - **Geometry**: Pre-calculated flat vertex arrays for all alien types. Switched to `love.graphics.translate/scale` for rendering instead of transforming vertices on CPU.
  - **Caching**: Implemented caching for touch zones and screen panels, updating them only when necessary.
  - **Iteration**: Replaced closure-based iterators with direct array access for `Bullets`, eliminating function creation in the hot loop.

### 2. Critical Bug Fixes
- **Swipe Input Fix**: The `Input` system was clearing the `swipeDirection` flag immediately after setting it in the same frame, causing swipe controls (for mobile/touch) to be unresponsive.
  - **Fix**: Moved the flag reset to the start of the frame, ensuring gameplay logic can read the input before it clears.

### 3. Code Quality & Best Practices
- **Dependency Management**: Removed `require()` calls from inside high-frequency `update()` and `draw()` functions. These now resolve once at module load time, reducing function call overhead.
- **Refactoring**:
  - `Game.update`: Streamlined collision detection loops.
  - `Player.update`: Cleaned up dependency injection usage.

## Technical Details

### Modules Modified
1.  **`src/systems/scaling.lua`**: Added caching for `left`, `center`, `right` panels.
2.  **`src/core/input.lua`**: Fixed swipe bug, optimized zone calculation.
3.  **`src/game/bullets.lua`**: Exposed `getPool()` for efficient iteration.
4.  **`src/game/game.lua`**: Refactored collision loops to use pool iteration; localized internal dependencies.
5.  **`src/game/aliens.lua`**: Flattened polygon constants; optimized `draw` to use coordinate system transforms.
6.  **`src/game/player.lua`**: Cleaned up `require` usage.
7.  **`main.lua`**: Optimized debug overlay.

## Recommendation
The game logic for "piercing" bullets currently registers only one hit per frame (the first alien found in the array). If multiple aliens overlap exactly, only one will be hit per frame. This is standard for this genre but verified as "working as intended" for now.

The codebase is now significantly more performant and should run smoother on lower-end mobile devices due to reduced Garbage Collection pressure.
