# Neon Invaders (LÖVE 11.x)

A retro-style space invaders game built with LÖVE 2D (11.x). Features neon aesthetics, wave-based gameplay, power-ups, and multiple platforms including desktop, Android, and web export.

## Quick Start

### Desktop
```bash
# Install LÖVE 11.5 (https://love2d.org/)
love .
```

### Web
```bash
# Export to web (requires LÖVE 11.5)
bash scripts/export-web.sh
# Or use LÖVE directly
love . --fused --export-type=web
```

## Gameplay

### Controls
- **Arrow Keys** or **WASD**: Move ship left/right
- **Space**: Fire bullets
- **P**: Pause game
- **Escape**: Return to title menu

### Objectives
- Destroy waves of alien enemies to earn points
- Collect power-ups to upgrade your ship
- Survive increasingly difficult waves
- Achieve high scores and compete on the leaderboard

### Game States
The game follows a simple state flow:
```
Title Screen → Playing → Pause/Game Over → Title Screen
```

## Architecture

The codebase is organized into several modules:

- **`src/core/`**: Core systems (input, state management)
- **`src/game/`**: Game logic (player, aliens, bullets, waves, boss)
- **`src/ui/`**: User interface components (HUD, menus, screens)
- **`src/fx/`**: Visual effects (particles, screenshake, starfield)
- **`src/audio/`**: Sound system and synthesis
- **`src/systems/`**: Supporting systems (save, cosmetics, scaling)

## Contributing

We welcome contributions! Here's how to get started:

1. **Fork the repository** and create a feature branch
2. **Run the game locally** to test your changes: `love .`
3. **Follow code style**:
   - Use `luacheck src/` to check for issues
   - Format with `stylua src/` if available
   - Follow existing patterns in the codebase
4. **Test thoroughly** on different platforms if possible
5. **Submit a pull request** with a clear description of changes

### Development Setup
```bash
# Clone your fork
git clone https://github.com/yourusername/neon-invaders.git
cd neon-invaders

# Create a feature branch
git checkout -b your-feature-name

# Run the game to test
love .
```

## Build Instructions

This repository contains a LÖVE 2D (11.x) game. It is configured to build Android APKs using the official love-android template via a lightweight wrapper in `android/` and a GitHub Actions pipeline.

## Android builds

We use the upstream `love-android` Gradle project as the engine, and package the game code as `game.love` into `app/src/main/assets/` during build.

- Package name: `com.neoninvaders.game`
- Min SDK: 19
- Target/Compile SDK: 34
- JDK: 17 (Temurin)

### Local (Debug APK)

Prereqs: Android SDK + platform tools (adb), Java 17, git, zip.

1) Bootstrap the Android project (downloads `love-android`):

```bash
bash android/bootstrap-android.sh
```

2) Build the debug APK:

```bash
cd android && ./gradlew assembleDebug
```

3) Install on device:

```bash
adb install -r android/love-android/app/build/outputs/apk/debug/app-debug.apk
```

### Local (Signed Release APK)

1) Create a keystore (once):

```bash
keytool -genkeypair -v -keystore release.keystore -alias neoninvaders \
  -keyalg RSA -keysize 2048 -validity 36500
base64 -w0 release.keystore > release.keystore.b64
```

2) Place files for local signing:

- Put `release.keystore` in `android/release.keystore`.
- Create `android/keystore.properties`:

```
storeFile=release.keystore
storePassword=YOUR_PASSWORD
keyAlias=neoninvaders
keyPassword=YOUR_KEY_PASSWORD
```

3) Build release:

```bash
cd android && ./gradlew assembleRelease
```

Outputs:
- Debug: `android/love-android/app/build/outputs/apk/debug/app-debug.apk`
- Release: `android/love-android/app/build/outputs/apk/release/app-release.apk`

## GitHub Actions CI

Workflow: `.github/workflows/android.yml`

- Debug job (runs on every push/PR):
  - Zips the repo to `game.love` (excludes .git, node_modules, build, etc.)
  - Clones `love-android` into `android/love-android`
  - Copies `game.love` into assets
  - Builds debug APK
  - Uploads the APK as an artifact

- Release job (runs only on `main`):
  - Additionally decodes a Base64 keystore and writes `keystore.properties`
  - Builds signed release APK (and optionally AAB if available)
  - Uploads artifacts

### Required repository secrets for Release

- `ANDROID_KEYSTORE_BASE64` – Base64 of your `release.keystore` (see above)
- `ANDROID_KEYSTORE_PASSWORD` – Keystore password
- `ANDROID_KEY_ALIAS` – Keystore alias (e.g., `neoninvaders`)
- `ANDROID_KEY_PASSWORD` – Key password (may be same as keystore password)

> Note: No passwords are hardcoded; CI reads from GitHub Secrets.

## Notes

- The `android/gradlew` script is a thin proxy that ensures the engine project is present and packages `game.love` before delegating to the engine's Gradle wrapper. This keeps the repo minimal and avoids committing large or volatile Android engine files.
- You can re-run `android/bootstrap-android.sh` at any time to refresh engine files.
- To change the application id or app label, the CI/bootstrap scripts already patch:
  - `applicationId` to `com.neoninvaders.game`
  - Android app label to `Neon Invaders`
