#!/usr/bin/env bash

set -euo pipefail

BUILD_DIR="$PWD/build-android"
APK_DIR="$BUILD_DIR/love-android/app/build/outputs/apk"

if [ -f "$BUILD_DIR/neon-invaders.apk" ]; then
    APK_PATH="$BUILD_DIR/neon-invaders.apk"
    echo "✅ SUCCESS: APK built successfully!"
    echo "📍 Location: $APK_PATH"
    echo "📱 Install with: adb install -r \"$APK_PATH\""
    echo ""
    echo "📋 APK size: $(du -h "$APK_PATH" | cut -f1)"
    exit 0
else
    echo "❌ ERROR: APK not found at expected location"
    echo "Expected: $BUILD_DIR/neon-invaders.apk"
    exit 1
fi