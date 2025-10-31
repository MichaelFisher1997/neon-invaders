{
  description = "Neon Invaders Android build env (Nix flake)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };
        ndkVer = "27.0.12077973";
        android = pkgs.androidenv.composeAndroidPackages {
          platformVersions = [ "34" ];
          buildToolsVersions = [ "34.0.0" ];
          cmakeVersions = [ "3.22.1" ];
          ndkVersion = ndkVer; # r27 to match AGP preferred
          includeEmulator = false;
          includeSources = false;
          includeSystemImages = false;
        };
        sdkRoot = "${android.androidsdk}/libexec/android-sdk";
        jdk = pkgs.jdk17;
        # NDK lives under the composed SDK: $SDK/ndk/<version>
        ndkPath = "${sdkRoot}/ndk/${ndkVer}";
        buildApp = pkgs.writeShellScriptBin "build" ''
          set -euo pipefail
          export ANDROID_SDK_ROOT="${sdkRoot}"
          export ANDROID_HOME="${sdkRoot}"
          export JAVA_HOME="${jdk.home}"
          export ANDROID_NDK_HOME="${ndkPath}"
          export ANDROID_NDK_ROOT="${ndkPath}"
          export PATH="${sdkRoot}/platform-tools:${sdkRoot}/tools/bin:${sdkRoot}/cmdline-tools/latest/bin:${sdkRoot}/cmake/3.22.1/bin:$PATH"

          # Run from repo root when invoked from scripts/ directory
          if [ -d "../android" ] && [ -d "." ] && [ -f "../main.lua" ]; then
            cd ..
          fi

          bash scripts/build-android-debug.sh
        '';
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            jdk
            android.androidsdk
            pkgs.git
            pkgs.zip
            pkgs.unzip
            pkgs.ninja
            pkgs.android-tools # adb
            pkgs.lua
            pkgs.luaPackages.busted
            pkgs.luaPackages.luacheck
            pkgs.stylua
          ];
          ANDROID_SDK_ROOT = sdkRoot;
          ANDROID_HOME = sdkRoot;
          JAVA_HOME = jdk.home;
          ANDROID_NDK_HOME = ndkPath;
          ANDROID_NDK_ROOT = ndkPath;
          shellHook = ''
            export PATH="${sdkRoot}/platform-tools:${sdkRoot}/tools/bin:${sdkRoot}/cmdline-tools/latest/bin:${sdkRoot}/cmake/3.22.1/bin:$PATH"
            echo "Android SDK: ${sdkRoot}"
            echo "JDK: $JAVA_HOME"
            echo "NDK: $ANDROID_NDK_HOME"
            echo "Use: nix run .#build (from scripts/) or nix run ./scripts#build (from repo root) to build the Debug APK"
          '';
        };

        apps.build = {
          type = "app";
          program = "${buildApp}/bin/build";
        };
        apps.default = self.outputs.apps.${system}.build;
      }
    );
}
