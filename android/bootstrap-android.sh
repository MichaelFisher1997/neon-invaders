#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
ENGINE_DIR="$ANDROID_DIR/love-android"

if [ ! -d "$ENGINE_DIR" ]; then
  echo "Cloning love-android template..."
  git clone --depth 1 https://github.com/love2d/love-android "$ENGINE_DIR"
else
  echo "love-android already present; pulling latest..."
  git -C "$ENGINE_DIR" pull --ff-only || true
fi

# Ensure assets dir
mkdir -p "$ENGINE_DIR/app/src/main/assets"

# Apply package name and app label
if grep -q "applicationId \"org.love2d.android\"" "$ENGINE_DIR/app/build.gradle"; then
  sed -i "s/applicationId \"org.love2d.android\"/applicationId \"com.neoninvaders.game\"/" "$ENGINE_DIR/app/build.gradle"
fi
if [ -f "$ENGINE_DIR/app/src/main/AndroidManifest.xml" ]; then
  sed -i 's/android:label="[^"]*"/android:label="Neon Invaders"/' "$ENGINE_DIR/app/src/main/AndroidManifest.xml" || true
fi

# Set sdk versions (min 19, target/compile 34)
sed -i 's/minSdkVersion [0-9][0-9]*/minSdkVersion 19/' "$ENGINE_DIR/app/build.gradle" || true
sed -i 's/targetSdkVersion [0-9][0-9]*/targetSdkVersion 34/' "$ENGINE_DIR/app/build.gradle" || true
sed -i 's/compileSdkVersion [0-9][0-9]*/compileSdkVersion 34/' "$ENGINE_DIR/app/build.gradle" || true

# Inject signing config loader
if ! grep -q "signing-config.gradle" "$ENGINE_DIR/app/build.gradle"; then
  printf "\napply from: '../../signing-config.gradle'\n" >> "$ENGINE_DIR/app/build.gradle"
fi

# Package game.love from repo root
cd "$ROOT_DIR"
ZIP_EXCLUDES=(
  "android/*"
  ".git/*"
  ".github/*"
  "**/node_modules/*"
  "**/build/*"
  "**/dist/*"
)
ZIP_ARGS=("-9" "-r" "game.love" ".")
for ex in "${ZIP_EXCLUDES[@]}"; do ZIP_ARGS+=("-x" "$ex"); done
zip "${ZIP_ARGS[@]}"
cp "$ROOT_DIR/game.love" "$ENGINE_DIR/app/src/main/assets/game.love"

cat <<EOF

Bootstrap complete.

Next steps:
  1) Build Debug APK:
       cd android/love-android && ./gradlew assembleDebug
     or from android/ wrapper:
       cd android && ./gradlew assembleDebug

  2) Install on device (debug):
       adb install -r android/love-android/app/build/outputs/apk/debug/app-debug.apk

  3) To sign Release locally, create android/keystore.properties with:
       storeFile=release.keystore
       storePassword=...\n       keyAlias=neoninvaders\n       keyPassword=...
     Place release.keystore as android/release.keystore
     Then run:
       cd android && ./gradlew assembleRelease

EOF
