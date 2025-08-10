#!/usr/bin/env bash
set -euo pipefail

# Local builder for a debug APK using love-android
# Usage:
#   APP_ID=com.neoninvaders.dev APP_NAME="Neon Invaders" bash scripts/build-android-debug.sh
# Env vars are optional. Defaults:
APP_ID="${APP_ID:-com.neoninvaders.game}"
APP_NAME="${APP_NAME:-Neon Invaders}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
TEMPLATE_DIR="$ANDROID_DIR/love-android"
ASSETS_DIR="$TEMPLATE_DIR/app/src/main/assets"

echo "[info] Root:        $ROOT_DIR"
echo "[info] Android:     $ANDROID_DIR"
echo "[info] love-android: $TEMPLATE_DIR"

# Ensure love-android exists (clone if missing)
if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "[info] Cloning love-android template..."
  git clone --recurse-submodules --depth 1 https://github.com/love2d/love-android "$TEMPLATE_DIR"
fi

# Prepare assets dir
mkdir -p "$ASSETS_DIR"

# Package game.love (exclude android/, VCS, web/, node_modules, build artifacts)
pushd "$ROOT_DIR" >/dev/null
rm -f game.love
zip -9 -r game.love . \
  -x "android/*" \
  -x ".git/*" \
  -x ".github/*" \
  -x "web/*" \
  -x "**/node_modules/*" \
  -x "**/build/*" \
  -x "**/dist/*"
cp game.love "$ASSETS_DIR/game.love"
popd >/dev/null

# Configure Android SDK/NDK locations for Gradle (prefer environment from Nix flake)
SDK_DIR="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [ -z "$SDK_DIR" ] && [ -d "$HOME/Android/Sdk" ]; then
  SDK_DIR="$HOME/Android/Sdk"
fi
NDK_DIR="${ANDROID_NDK_HOME:-}"
if [ -n "$SDK_DIR" ]; then
  SDK_DIR_ABS="$(readlink -f "$SDK_DIR" 2>/dev/null || realpath "$SDK_DIR" 2>/dev/null || echo "$SDK_DIR")"
  echo "[info] Using Android SDK at: $SDK_DIR_ABS"
  # If NDK env var is not set or invalid, try to auto-discover within the SDK
  if [ -z "$NDK_DIR" ] || [ ! -d "$NDK_DIR" ]; then
    if [ -d "$SDK_DIR_ABS/ndk" ]; then
      CAND=$(ls -1d "$SDK_DIR_ABS/ndk"/* 2>/dev/null | head -n 1 || true)
      if [ -n "$CAND" ] && [ -d "$CAND" ]; then
        NDK_DIR="$CAND"
      fi
    fi
    if [ -z "$NDK_DIR" ] || [ ! -d "$NDK_DIR" ]; then
      if [ -d "$SDK_DIR_ABS/ndk-bundle" ]; then
        NDK_DIR="$SDK_DIR_ABS/ndk-bundle"
      fi
    fi
    # Fallback scan: find any NDK under SDK with source.properties
    if [ -z "$NDK_DIR" ] || [ ! -d "$NDK_DIR" ]; then
      CAND=$(find "$SDK_DIR_ABS" -maxdepth 4 -type f -name source.properties -path "*/ndk/*/source.properties" 2>/dev/null | head -n 1 || true)
      if [ -n "$CAND" ]; then
        NDK_DIR="$(dirname "$CAND")"
      fi
    fi
    # Fallback scan: locate ndk-build binary
    if [ -z "$NDK_DIR" ] || [ ! -d "$NDK_DIR" ]; then
      CAND=$(find "$SDK_DIR_ABS" -maxdepth 4 -type f -name ndk-build 2>/dev/null | head -n 1 || true)
      if [ -n "$CAND" ]; then
        NDK_DIR="$(dirname "$CAND")"
      fi
    fi
  fi
  : > "$TEMPLATE_DIR/local.properties"
  printf 'sdk.dir=%s\n' "$SDK_DIR_ABS" >> "$TEMPLATE_DIR/local.properties"
  # Always remove stale ndk.dir before optionally re-adding it
  sed -i '/^ndk\.dir=/d' "$TEMPLATE_DIR/local.properties" 2>/dev/null || true
  : > "$ANDROID_DIR/local.properties"
  printf 'sdk.dir=%s\n' "$SDK_DIR_ABS" >> "$ANDROID_DIR/local.properties"
  sed -i '/^ndk\.dir=/d' "$ANDROID_DIR/local.properties" 2>/dev/null || true
  if [ -n "$NDK_DIR" ]; then
    NDK_DIR_ABS="$(readlink -f "$NDK_DIR" 2>/dev/null || realpath "$NDK_DIR" 2>/dev/null || echo "$NDK_DIR")"
    echo "[info] Using Android NDK at: $NDK_DIR_ABS"
    if [ -d "$NDK_DIR_ABS" ]; then
      # Clean any stale ndk.dir/android.ndkPath entries to prevent CXX1102 errors
      sed -i '/^ndk\.dir=/d' "$TEMPLATE_DIR/local.properties" 2>/dev/null || true
      sed -i '/^ndk\.dir=/d' "$ANDROID_DIR/local.properties" 2>/dev/null || true
      # Explicitly set ndk.dir to the absolute NDK path (not a symlink)
      printf 'ndk.dir=%s\n' "$NDK_DIR_ABS" >> "$TEMPLATE_DIR/local.properties"
      printf 'ndk.dir=%s\n' "$NDK_DIR_ABS" >> "$ANDROID_DIR/local.properties"
      # Optionally export env vars; AGP primarily uses sdk.dir + ndkVersion
      export ANDROID_NDK="$NDK_DIR_ABS"
      export ANDROID_NDK_HOME="$NDK_DIR_ABS"
      export ANDROID_NDK_ROOT="$NDK_DIR_ABS"
      # Detect actual NDK version from source.properties or path basename
      NDK_VER_DETECTED=""
      if [ -f "$NDK_DIR_ABS/source.properties" ]; then
        NDK_VER_DETECTED="$(sed -n 's/^Pkg.Revision=\(.*\)$/\1/p' "$NDK_DIR_ABS/source.properties" | tr -d '[:space:]' | head -n1)"
      fi
      if [ -z "$NDK_VER_DETECTED" ]; then
        NDK_VER_DETECTED="$(basename "$NDK_DIR_ABS" | tr -d '[:space:]')"
      fi
      echo "[info] Detected NDK version: ${NDK_VER_DETECTED:-unknown}"
    else
      echo "[warn] NDK path does not exist: $NDK_DIR_ABS; skipping ndk.dir/android.ndkPath writes"
    fi
    # Also hint AGP to use the exact NDK version to avoid installs
    if [ -f "$TEMPLATE_DIR/app/build.gradle" ]; then
      # Replace ndkVersion whether it's single- or double-quoted
      sed -i -E "s/(ndkVersion\s+['\"]).*(['\"]).*/\1${NDK_VER_DETECTED:-27.0.12077973}\2/" "$TEMPLATE_DIR/app/build.gradle" || true
      # Inject into android { } block when it's missing
      if ! grep -q "ndkVersion" "$TEMPLATE_DIR/app/build.gradle" 2>/dev/null; then
        sed -i "/^android[[:space:]]*{.*/a \\    ndkVersion \"${NDK_VER_DETECTED:-27.0.12077973}\"" "$TEMPLATE_DIR/app/build.gradle" || true
      fi
    else
      : # Module build file is absent; continue with properties hints below
    fi
    # Always provide android.ndkVersion as a backup hint in both gradle.properties files
    sed -i '/^android\.ndkVersion=/d' "$TEMPLATE_DIR/gradle.properties" 2>/dev/null || true
    sed -i '/^android\.ndkVersion=/d' "$ANDROID_DIR/gradle.properties" 2>/dev/null || true
    echo "android.ndkVersion=${NDK_VER_DETECTED:-27.0.12077973}" >> "$TEMPLATE_DIR/gradle.properties"
    echo "android.ndkVersion=${NDK_VER_DETECTED:-27.0.12077973}" >> "$ANDROID_DIR/gradle.properties"
    # For hermetic builds: prevent AGP from attempting to download SDK components
    if ! grep -q "android.builder.sdkDownload" "$TEMPLATE_DIR/gradle.properties" 2>/dev/null; then
      echo "android.builder.sdkDownload=false" >> "$TEMPLATE_DIR/gradle.properties"
    fi
    if ! grep -q "android.builder.sdkDownload" "$ANDROID_DIR/gradle.properties" 2>/dev/null; then
      echo "android.builder.sdkDownload=false" >> "$ANDROID_DIR/gradle.properties"
    fi
    # Always remove stale android.ndkPath first
    sed -i '/^android\.ndkPath=/d' "$TEMPLATE_DIR/gradle.properties" 2>/dev/null || true
    sed -i '/^android\.ndkPath=/d' "$ANDROID_DIR/gradle.properties" 2>/dev/null || true
    # Set android.ndkPath to the real NDK path (not a symlink) if it exists
    if [ -d "$NDK_DIR_ABS" ]; then
      echo "android.ndkPath=$NDK_DIR_ABS" >> "$TEMPLATE_DIR/gradle.properties"
      echo "android.ndkPath=$NDK_DIR_ABS" >> "$ANDROID_DIR/gradle.properties"
    fi
  fi
else
  echo "[warn] ANDROID_SDK_ROOT/ANDROID_HOME not set and ~/Android/Sdk not found."
  echo "[warn] Please install Android SDK/NDK and set ANDROID_SDK_ROOT, e.g.:"
  echo '       export ANDROID_SDK_ROOT="$HOME/Android/Sdk"; export ANDROID_HOME="$ANDROID_SDK_ROOT"'
fi

# Apply package name and user-visible label
if [ -f "$TEMPLATE_DIR/app/build.gradle" ]; then
  sed -i "s/applicationId \"org.love2d.android\"/applicationId \"${APP_ID//\//\\/}\"/" "$TEMPLATE_DIR/app/build.gradle" || true
  # Align SDK levels with Nix flake (API 34)
  sed -i -E 's/(compileSdk) [0-9]+/\1 34/' "$TEMPLATE_DIR/app/build.gradle" || true
  sed -i -E 's/(targetSdk) [0-9]+/\1 34/' "$TEMPLATE_DIR/app/build.gradle" || true
  # Ensure build tools version is available in nixpkgs
  sed -i -E 's/(buildToolsVersion\s+\")[0-9.]+(\")/\134.0.0\2/' "$TEMPLATE_DIR/app/build.gradle" || true
fi
if [ -f "$TEMPLATE_DIR/app/src/main/AndroidManifest.xml" ]; then
  sed -i "s/android:label=\"[^\"]*\"/android:label=\"$APP_NAME\"/" "$TEMPLATE_DIR/app/src/main/AndroidManifest.xml" || true
fi

# Optional: copy placeholder icons if present
if [ -d "$ANDROID_DIR/icons" ]; then
  mkdir -p "$TEMPLATE_DIR/app/src/main/res"
  cp -r "$ANDROID_DIR/icons/"* "$TEMPLATE_DIR/app/src/main/res/" || true
fi

# Diagnostics: verify NDK presence and expected layout
EXPECTED_NDK_VER="27.0.12077973"
if [ -n "${SDK_DIR_ABS:-}" ]; then
  EXPECTED_NDK_DIR="$SDK_DIR_ABS/ndk/$EXPECTED_NDK_VER"
  echo "[diag] SDK dir: $SDK_DIR_ABS"
  echo "[diag] Expected NDK: $EXPECTED_NDK_DIR"
  if [ -d "$EXPECTED_NDK_DIR" ]; then
    echo "[diag] Found expected NDK directory."
    if [ -f "$EXPECTED_NDK_DIR/source.properties" ]; then
      echo "[diag] NDK source.properties (first lines):"
      sed -n '1,20p' "$EXPECTED_NDK_DIR/source.properties" || true
    fi
    if [ -d "$EXPECTED_NDK_DIR/toolchains/llvm/prebuilt" ]; then
      echo "[diag] LLVM prebuilt toolchains present:"
      ls -1 "$EXPECTED_NDK_DIR/toolchains/llvm/prebuilt" || true
    else
      echo "[warn] LLVM prebuilt toolchains directory missing under expected NDK."
    fi
  else
    echo "[warn] Expected NDK dir not found; listing available entries under $SDK_DIR_ABS/ndk (if any):"
    ls -la "$SDK_DIR_ABS/ndk" 2>/dev/null || echo "[diag] No side-by-side NDKs under SDK."
  fi
fi

# Build Debug APK (uses android/gradlew wrapper)
echo "[info] Building Debug APK (this may take a while on first run)..."
bash "$ANDROID_DIR/gradlew" assembleDebug

APK_DIR="$TEMPLATE_DIR/app/build/outputs/apk/debug"
if compgen -G "$APK_DIR/*.apk" > /dev/null; then
  APK_PATH="$(ls -1 "$APK_DIR"/*.apk | head -n 1)"
  echo "[success] APK built: $APK_PATH"
  echo "[hint] Install via USB: adb install -r \"$APK_PATH\""
  echo "[hint] Or share the APK file to your phone and install (enable Unknown Sources)."
else
  echo "[error] Build finished but no APK found in $APK_DIR" >&2
  exit 1
fi
