{
  description = "Neon Invaders - LÖVE2D game with Android build support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Android SDK and NDK versions
        androidSdk = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [ "34.0.0" ];
          platformVersions = [ "34" ];
          abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
          ndkVersion = "27.0.12077973";
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
          
          # Package game.love
          rm -f game.love
          zip -9 -r game.love . \
            -x "android/*" \
            -x ".git/*" \
            -x ".github/*" \
            -x "**/node_modules/*" \
            -x "**/build/*" \
            -x "**/dist/*"
          cp game.love "$ASSETS_DIR/game.love"
          
          # Configure Android SDK/NDK paths
          export ANDROID_SDK_ROOT="${androidEnv}/libexec/android-sdk"
          export ANDROID_HOME="$ANDROID_SDK_ROOT"
          export ANDROID_NDK_ROOT="$ANDROID_SDK_ROOT/ndk/27.0.12077973"
          export ANDROID_NDK_HOME="$ANDROID_NDK_ROOT"
          export ANDROID_NDK="$ANDROID_NDK_ROOT"
          
          # Create local.properties
          cat > "$TEMPLATE_DIR/local.properties" << EOF
          sdk.dir=$ANDROID_SDK_ROOT
          ndk.dir=$ANDROID_NDK_ROOT
          EOF
          
          cat > "$ANDROID_DIR/local.properties" << EOF
          sdk.dir=$ANDROID_SDK_ROOT
          ndk.dir=$ANDROID_NDK_ROOT
          EOF
          
          # Configure gradle.properties
          cat > "$TEMPLATE_DIR/gradle.properties" << EOF
          android.ndkVersion=27.0.12077973
          android.ndkPath=$ANDROID_NDK_ROOT
          android.builder.sdkDownload=false
          EOF
          
          cat > "$ANDROID_DIR/gradle.properties" << EOF
          android.ndkVersion=27.0.12077973
          android.ndkPath=$ANDROID_NDK_ROOT
          android.builder.sdkDownload=false
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
          cd "$ANDROID_DIR"
          ./gradlew assembleDebug
          
          APK_DIR="$TEMPLATE_DIR/app/build/outputs/apk/debug"
          if compgen -G "$APK_DIR/*.apk" > /dev/null; then
            APK_PATH="$(ls -1 "$APK_DIR"/*.apk | head -n 1)"
            echo "[success] APK built: $APK_PATH"
            echo "[hint] Install via USB: adb install -r \"$APK_PATH\""
          else
            echo "[error] Build finished but no APK found in $APK_DIR" >&2
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
            export ANDROID_NDK_ROOT="$ANDROID_SDK_ROOT/ndk/27.0.12077973"
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