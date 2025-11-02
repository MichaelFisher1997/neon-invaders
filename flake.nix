{
  description = "Neon Invaders - LÖVE2D game with Android build support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
        pkgs = import nixpkgs {
          inherit system config;
        };
        
        # Android SDK and NDK versions
        androidSdk = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [ "34.0.0" ];
          platformVersions = [ "34" ];
          abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
          includeNDK = true;
          ndkVersions = [ "27.1.12297006" ];
        };
        
        androidEnv = androidSdk.androidsdk;
        
        # Build script for Android APK
        buildAndroid = pkgs.writeShellScriptBin "build-android" ''
          set -euo pipefail
          
          ROOT_DIR="$(pwd)"
          ANDROID_DIR="$ROOT_DIR/android"
          TEMPLATE_DIR="$ANDROID_DIR/love-android"
          ASSETS_DIR="$TEMPLATE_DIR/app/src/main/assets"
          
          echo "[info] Building Neon Invaders Android APK"
          echo "[info] Root: $ROOT_DIR"
          echo "[info] Android: $ANDROID_DIR"
          
          # Ensure love-android exists
          if [ ! -d "$TEMPLATE_DIR" ]; then
            echo "[info] Cloning love-android template..."
            git clone --recurse-submodules --depth 1 https://github.com/love2d/love-android "$TEMPLATE_DIR"
          fi
          
          # Prepare assets dir
          mkdir -p "$ASSETS_DIR"
          
# Package game.love (only include essential game files)
          rm -f game.love
          cd "$ROOT_DIR"
          zip -9 -r game.love src/ main.lua conf.lua
          
          # Verify game.love size and content before copying
          GAME_LOVE_SIZE=$(stat -c%s game.love)
          if [ "$GAME_LOVE_SIZE" -gt 1000000 ]; then
            echo "[error] game.love is too large ($GAME_LOVE_SIZE bytes), likely includes unwanted files" >&2
            exit 1
          fi
          
          # Copy to assets directory
          cp game.love "$ASSETS_DIR/game.love"
          
          # Configure Android SDK/NDK paths
            export ANDROID_SDK_ROOT="${androidEnv}/libexec/android-sdk"
            export ANDROID_HOME="$ANDROID_SDK_ROOT"
            export ANDROID_NDK_ROOT="${androidEnv}/libexec/android-sdk/ndk/27.1.12297006"
            export ANDROID_NDK_HOME="$ANDROID_NDK_ROOT"
            export ANDROID_NDK="$ANDROID_NDK_ROOT"
            export JAVA_HOME="${pkgs.jdk17}/lib/openjdk"
          
          # Create local.properties
          cat > "$TEMPLATE_DIR/local.properties" << EOF
sdk.dir=$ANDROID_SDK_ROOT
EOF
          
          cat > "$ANDROID_DIR/local.properties" << EOF
sdk.dir=$ANDROID_SDK_ROOT
ndk.dir=$ANDROID_NDK_ROOT
EOF
          
          # Configure gradle.properties
          cat > "$TEMPLATE_DIR/gradle.properties" << EOF
android.ndkVersion=27.1.12297006
android.ndkPath=$ANDROID_NDK_ROOT
android.builder.sdkDownload=false
android.useAndroidX=true
app.application_id=com.neoninvaders.game
app.version_code=1
app.version_name=1.0
app.name=Neon Invaders
app.orientation=landscape
org.gradle.jvmargs=-Xmx6g -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8
org.gradle.parallel=true
org.gradle.daemon=true
android.enableJetifier=true
EOF
          
          cat > "$ANDROID_DIR/gradle.properties" << EOF
android.ndkVersion=27.1.12297006
android.ndkPath=$ANDROID_NDK_ROOT
android.builder.sdkDownload=false
org.gradle.jvmargs=-Xmx6g -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8
org.gradle.parallel=true
org.gradle.daemon=true
android.enableJetifier=true
EOF
          
          # Apply package name and app label
          if [ -f "$TEMPLATE_DIR/app/build.gradle" ]; then
            sed -i 's/applicationId "org.love2d.android"/applicationId "com.neoninvaders.game"/' "$TEMPLATE_DIR/app/build.gradle" || true
            sed -i 's/compileSdk [0-9]*/compileSdk 34/' "$TEMPLATE_DIR/app/build.gradle" || true
            sed -i 's/targetSdk [0-9]*/targetSdk 34/' "$TEMPLATE_DIR/app/build.gradle" || true
            sed -i 's/buildToolsVersion "[0-9.]*/buildToolsVersion "34.0.0"/' "$TEMPLATE_DIR/app/build.gradle" || true
          fi
          
          if [ -f "$TEMPLATE_DIR/app/src/main/AndroidManifest.xml" ]; then
            sed -i 's/android:label="[^"]*"/android:label="Neon Invaders"/' "$TEMPLATE_DIR/app/src/main/AndroidManifest.xml" || true
          fi
          
          # Copy icons if available
          if [ -d "$ANDROID_DIR/icons" ]; then
            mkdir -p "$TEMPLATE_DIR/app/src/main/res"
            cp -r "$ANDROID_DIR/icons/"* "$TEMPLATE_DIR/app/src/main/res/" || true
          fi
          
          # Build Debug APK
          echo "[info] Building Debug APK..."
          
          # Store original game.love checksum to detect unwanted changes
          ORIGINAL_CHECKSUM=$(md5sum "$TEMPLATE_DIR/app/src/main/assets/game.love" | cut -d' ' -f1)
          
          # Create a clean build directory to avoid unwanted file inclusion
          BUILD_DIR="$ROOT_DIR/build-android"
          mkdir -p "$BUILD_DIR"
          cd "$BUILD_DIR"
          
          # Copy only the android template to build directory (excluding .git)
          rsync -av --exclude='.git' "$TEMPLATE_DIR" ./
          
          # Copy android configuration files
          if [ -f "$ANDROID_DIR/signing-config.gradle" ]; then
            cp "$ANDROID_DIR/signing-config.gradle" ./
          fi
          
          # Run gradle from the clean build directory with proper environment
          export ANDROID_SDK_ROOT="${androidEnv}/libexec/android-sdk"
          export ANDROID_HOME="$ANDROID_SDK_ROOT"
          export ANDROID_NDK_ROOT="${androidEnv}/libexec/android-sdk/ndk/27.1.12297006"
          export ANDROID_NDK_HOME="$ANDROID_NDK_ROOT"
          export ANDROID_NDK="$ANDROID_NDK_ROOT"
          export NIXPKGS_ACCEPT_ANDROID_SDK_LICENSE=1
          export GRADLE_OPTS="-Xmx6g -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8"

          ./love-android/gradlew -p love-android assembleNormalNoRecordDebug
          
          # Verify game.love wasn't modified during build
          CURRENT_CHECKSUM=$(md5sum "love-android/app/src/main/assets/game.love" | cut -d' ' -f1)
          if [ "$ORIGINAL_CHECKSUM" != "$CURRENT_CHECKSUM" ]; then
            echo "[error] game.love was modified during gradle build!" >&2
            echo "[hint] Some gradle task is incorrectly packaging files" >&2
            exit 1
          fi
          
          APK_DIR="$BUILD_DIR/love-android/app/build/outputs/apk"

          if [ -f "$APK_DIR/normalNoRecord/debug/app-normal-noRecord-debug.apk" ]; then
            APK_PATH="$APK_DIR/normalNoRecord/debug/app-normal-noRecord-debug.apk"
            # Rename APK to neon-invaders.apk
            NEON_APK_PATH="$BUILD_DIR/neon-invaders.apk"
            cp "$APK_PATH" "$NEON_APK_PATH"
            echo "[success] APK built: $NEON_APK_PATH"
            echo "[hint] Install via USB: adb install -r \"$NEON_APK_PATH\""
          else
            echo "[error] Build finished but no APK found in $APK_DIR/normalNoRecord/debug/" >&2
            exit 1
          fi
        '';
        
        # Development shell with Android tools
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            git
            zip
            jdk17
            androidEnv
            buildAndroid
          ];
          
          shellHook = ''
            export ANDROID_SDK_ROOT="${androidEnv}/libexec/android-sdk"
            export ANDROID_HOME="$ANDROID_SDK_ROOT"
          export ANDROID_NDK_ROOT="${androidEnv}/libexec/android-sdk/ndk/27.1.12297006"
            export ANDROID_NDK_HOME="$ANDROID_NDK_ROOT"
            export ANDROID_NDK="$ANDROID_NDK_ROOT"
            
            echo "Android development environment ready"
            echo "Run 'build-android' to build the APK"
          '';
        };
        
      in {
        packages = {
          inherit buildAndroid;
          default = buildAndroid;
        };
        
        devShells.default = devShell;
      });
}