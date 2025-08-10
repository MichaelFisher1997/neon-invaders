# Android NDK detection on NixOS — Build fails with "NDK not configured" / CXX1102

This document captures the current state, errors, and a concrete plan to fix the Android APK build on NixOS using the Nix flake. Use this to resume work after a context reset.

## Summary
- Goal: Build a Debug APK for the LÖVE game using `love-android` under a reproducible Nix flake.
- Environment: Nix flake provisions Android SDK, NDK, CMake, and JDK.
- Current error variants during `assembleDebug`:
  - CXX1102: `ndk.dir` pointed at `.ndk` symlink considered invalid by Gradle/AGP.
  - After removing symlink usage: `NDK not configured. Preferred NDK version is '27.0.12077973'.`

## Environment (from flake)
- File: `scripts/flake.nix`
  - Nix channel: `nixos-24.05`
  - Android SDK (side-by-side layout): `${android.androidsdk}/libexec/android-sdk`
  - CMake: 3.22.1
  - Platform/Build-tools: API 34 / 34.0.0
  - JDK: `jdk17`
  - NDK version variable: `ndkVer = "27.1.12297006"` (r27b)
- `nix run ./scripts#build` runs `scripts/build-android-debug.sh` inside the flake’s env with these env vars exported:
  - `ANDROID_SDK_ROOT` / `ANDROID_HOME`: SDK root
  - `ANDROID_NDK_HOME` / `ANDROID_NDK_ROOT`: `${SDK}/ndk/27.1.12297006`
  - PATH includes SDK tools + CMake 3.22.1

## Project layout
- Android template: `android/love-android/` (cloned from `love2d/love-android`)
- Wrapper: `android/gradlew`
- Build script: `scripts/build-android-debug.sh`

## Current behavior and symptoms
- Earlier: `ndk.dir` pointed to `android/love-android/.ndk` symlink => AGP rejected with:
  - `[CXX1102] Location specified by ndk.dir (...) did not contain a valid NDK`
- After switching strategy (remove symlink, rely on sdk.dir + ndkVersion), Gradle now fails with:
  - `NDK not configured. Download it with SDK manager. Preferred NDK version is '27.0.12077973'.`
- Keystore warning for release is benign; Debug build still should proceed without signing config.

## What we changed (latest)
- In `scripts/flake.nix`:
  - Set `ndkVer = "27.1.12297006"` (r27b) and expose SDK/NDK via env vars.
- In `scripts/build-android-debug.sh`:
  - Create `game.love` and place into `android/love-android/app/src/main/assets/`.
  - Write `sdk.dir` to both `android/local.properties` and `android/love-android/local.properties`.
  - Auto-discover NDK under `${ANDROID_SDK_ROOT}/ndk/<ver>` if `ANDROID_NDK_HOME` unset.
  - Export `ANDROID_NDK`, `ANDROID_NDK_HOME`, `ANDROID_NDK_ROOT` to the absolute side-by-side NDK path (no symlink).
  - Ensure `app/build.gradle` contains `ndkVersion "27.1.12297006"` (inject if missing; replace if present).
  - In both `android/gradle.properties` and `android/love-android/gradle.properties`:
    - Set `android.ndkVersion=27.1.12297006` (replace, don’t append duplicates).
    - Set `android.builder.sdkDownload=false`.
    - Set `android.ndkPath=<absolute NDK path>` (no symlink).
  - In both `local.properties` files: remove any stale `ndk.dir`/`android.ndkPath`, then write `ndk.dir=<absolute NDK path>` (no symlink).

## Likely causes
- AGP prefers r27 (27.0.12077973). We’re installing r27b (27.1.12297006) via Nix. AGP can work with r27b when explicitly configured, but any leftover config pointing to r27 or a non-existent path triggers the error.
- Any of these lingering issues will cause failure:
  - `android.ndkVersion` still set to `27.0.12077973` somewhere.
  - `ndk.dir` or `android.ndkPath` still points at a symlink (`.ndk`) or a non-existent directory.
  - `app/build.gradle` missing or overriding `ndkVersion`.
  - `sdk.dir` not set in the exact `local.properties` AGP is reading.

## Reproduce
- From repo root (preferred):
  ```bash
  nix run ./scripts#build
  ```
- Or from `scripts/` dir:
  ```bash
  nix run .#build
  ```

## Immediate diagnostics (run and capture output)
```bash
# Show properties AGP reads
sed -n '1,200p' android/local.properties || true
sed -n '1,200p' android/love-android/local.properties || true
sed -n '1,200p' android/gradle.properties || true
sed -n '1,200p' android/love-android/gradle.properties || true

# Confirm ndkVersion in the module build file
sed -n '1,260p' android/love-android/app/build.gradle || true

# Verify NDK directory exists and is complete
NDK=$(grep -E '^ndk.dir=' android/local.properties | sed 's/ndk.dir=//')
echo "NDK=$NDK"
ls -la "$NDK" || true
sed -n '1,80p' "$NDK/source.properties" || true
ls -la "$NDK/toolchains/llvm/prebuilt" || true

# Check installed side-by-side NDKs
ls -la "$ANDROID_SDK_ROOT/ndk" || true
```

## Two viable configuration strategies (choose one and keep it consistent)
1) Prefer side-by-side discovery (cleaner):
   - Ensure `local.properties` has only:
     - `sdk.dir=<absolute SDK path>`
   - Ensure `app/build.gradle`:
     - Inside `android {}` add `ndkVersion "27.1.12297006"`
   - Do NOT set `ndk.dir` or `android.ndkPath` anywhere.
   - Keep `android.ndkVersion=27.1.12297006` in `gradle.properties` as a backup hint.

2) Explicit path (works when AGP insists):
   - In both `local.properties` files:
     - `sdk.dir=<absolute SDK path>`
     - `ndk.dir=<absolute NDK path>` (no symlink; must contain `source.properties`)
   - In both `gradle.properties` files:
     - `android.ndkVersion=27.1.12297006`
     - `android.ndkPath=<absolute NDK path>`

Note: Avoid pointing `ndk.dir` to a symlink (`.ndk`) — some AGP checks reject it.

## If AGP continues to prefer r27 (27.0.12077973)
- Option A (change Nix): Switch flake to `ndkVer = "27.0.12077973"` so the side-by-side NDK matches AGP’s preferred version. Then keep strategy (1) above.
- Option B (pin Gradle config): Keep r27b, but make sure `app/build.gradle` and both `gradle.properties` files consistently pin `27.1.12297006`, and `local.properties` points directly to the actual NDK directory.

## Known non-blockers
- `[signing-config] No keystore.properties found; building unsigned release` is normal for Debug. Release signing is handled separately.

## Next actions (checklist)
- [ ] Confirm `local.properties` (both locations) have correct `sdk.dir` and, if used, an absolute `ndk.dir` (no symlink).
- [ ] Confirm `gradle.properties` (both locations) contain `android.ndkVersion=27.1.12297006` and, if used, `android.ndkPath=<abs>`.
- [ ] Confirm `app/build.gradle` has `ndkVersion "27.1.12297006"` inside `android {}`.
- [ ] Verify the NDK directory contains `source.properties` and `toolchains/llvm/prebuilt/*`.
- [ ] Re-run `nix run ./scripts#build` with `--stacktrace` if it fails and capture logs.
- [ ] If still failing with "Preferred NDK is 27.0.12077973": either
      - switch flake NDK to `27.0.12077973`, or
      - keep r27b and remove all `ndk.dir`/`android.ndkPath` (strategy 1), or
      - keep r27b and set both explicitly (strategy 2) but ensure absolute, non-symlink paths.

## Useful commands
```bash
# Run build with Gradle debug logging
( cd android && ./gradlew --stacktrace --info :love-android:assembleDebug )

# Enter dev shell instead of one-shot build
nix develop ./scripts -c bash
# then run the script
bash scripts/build-android-debug.sh
```

## Files to inspect/edit
- `scripts/flake.nix`
- `scripts/build-android-debug.sh`
- `android/local.properties`
- `android/gradle.properties`
- `android/love-android/local.properties`
- `android/love-android/gradle.properties`
- `android/love-android/app/build.gradle`

## Notes
- AGP NDK checks are strict. Prefer absolute, real paths (no symlinks) for `ndk.dir`.
- Side-by-side NDK location is `${ANDROID_SDK_ROOT}/ndk/<version>`. Ensure that directory exists under the Nix-provided SDK path and contains `source.properties`.
