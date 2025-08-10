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
  : > "$TEMPLATE_DIR/local.properties"
  printf 'sdk.dir=%s\n' "$SDK_DIR_ABS" >> "$TEMPLATE_DIR/local.properties"
  : > "$ANDROID_DIR/local.properties"
  printf 'sdk.dir=%s\n' "$SDK_DIR_ABS" >> "$ANDROID_DIR/local.properties"
  if [ -n "$NDK_DIR" ]; then
    NDK_DIR_ABS="$(readlink -f "$NDK_DIR" 2>/dev/null || realpath "$NDK_DIR" 2>/dev/null || echo "$NDK_DIR")"
    echo "[info] Using Android NDK at: $NDK_DIR_ABS"
    # Create a project-local symlink so Gradle won't try to write into the read-only Nix store
    NDK_LINK="$TEMPLATE_DIR/.ndk"
    rm -f "$NDK_LINK" && ln -s "$NDK_DIR_ABS" "$NDK_LINK"
    printf 'ndk.dir=%s\n' "$NDK_LINK" >> "$TEMPLATE_DIR/local.properties"
    printf 'android.ndkPath=%s\n' "$NDK_LINK" >> "$TEMPLATE_DIR/local.properties" || true
    printf 'ndk.dir=%s\n' "$NDK_LINK" >> "$ANDROID_DIR/local.properties"
    printf 'android.ndkPath=%s\n' "$NDK_LINK" >> "$ANDROID_DIR/local.properties" || true
    # Also export env vars that AGP/CMake may read
    export ANDROID_NDK="$NDK_LINK"
    export ANDROID_NDK_HOME="$NDK_LINK"
    export ANDROID_NDK_ROOT="$NDK_LINK"
    # Also hint AGP to use the exact NDK version to avoid installs
    if [ -f "$TEMPLATE_DIR/app/build.gradle" ]; then
      # Replace ndkVersion whether it's single- or double-quoted
      sed -i -E "s/(ndkVersion\s+['\"]).*(['\"]).*/\127.0.12077973\2/" "$TEMPLATE_DIR/app/build.gradle" || true
      if ! grep -q "ndkVersion" "$TEMPLATE_DIR/app/build.gradle" 2>/dev/null; then
        # Inject into android { } block
        sed -i '/^android[[:space:]]*{.*/a \\    ndkVersion "27.0.12077973"' "$TEMPLATE_DIR/app/build.gradle" || true
        echo "android.ndkVersion=27.0.12077973" >> "$TEMPLATE_DIR/gradle.properties"
        echo "android.ndkVersion=27.0.12077973" >> "$ANDROID_DIR/gradle.properties"
      fi
    else
      echo "android.ndkVersion=27.0.12077973" >> "$TEMPLATE_DIR/gradle.properties"
      echo "android.ndkVersion=27.0.12077973" >> "$ANDROID_DIR/gradle.properties"
    fi
    # For hermetic builds: prevent AGP from attempting to download SDK components
    if ! grep -q "android.builder.sdkDownload" "$TEMPLATE_DIR/gradle.properties" 2>/dev/null; then
      echo "android.builder.sdkDownload=false" >> "$TEMPLATE_DIR/gradle.properties"
    fi
    if ! grep -q "android.builder.sdkDownload" "$ANDROID_DIR/gradle.properties" 2>/dev/null; then
      echo "android.builder.sdkDownload=false" >> "$ANDROID_DIR/gradle.properties"
    fi
    # Ensure gradle.properties also contains the NDK path
    if ! grep -q "^android.ndkPath=" "$TEMPLATE_DIR/gradle.properties" 2>/dev/null; then
      echo "android.ndkPath=$NDK_LINK" >> "$TEMPLATE_DIR/gradle.properties"
    fi
    if ! grep -q "^android.ndkPath=" "$ANDROID_DIR/gradle.properties" 2>/dev/null; then
      echo "android.ndkPath=$NDK_LINK" >> "$ANDROID_DIR/gradle.properties"
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
