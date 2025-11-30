{
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  flake-utils.url = "github:numtide/flake-utils";
};
outputs = { self, nixpkgs, flake-utils }:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          android_sdk.accept_license = true;
          allowUnfree = true;
        };
      };
      sdk-args = {
        buildToolsVersions = [ "35.0.0" ];
        platformVersions = [ "33" "34" "35" "36" ];
        includeNDK = true;
        ndkVersions = [ "28.2.13676358" ];
        cmakeVersions = [ "3.22.1" ];
      };
      android-comp = pkgs.androidenv.composeAndroidPackages sdk-args;
      android-sdk = android-comp.androidsdk;
      android-sdk-root = "${android-sdk}/libexec/android-sdk";
      android-emulator = pkgs.androidenv.emulateApp {
          name = "Emulator";
          platformVersion = "35";
          systemImageType = "google_apis";
          abiVersion = "x86_64";
          configOptions = {
            # https://android.googlesource.com/platform/external/qemu/+/refs/heads/master/android/avd/hardware-properties.ini
            "hw.ramSize" = "4096";
            "hw.lcd.width" = "1170";
            "hw.lcd.height" = "2532";
            "hw.lcd.density" = "460";
            "hw.keyboard" = "yes";
          };
          sdkExtraArgs = sdk-args;
        };
    in
    {
      devShell =
        with pkgs; mkShell rec {
          ANDROID_SDK_ROOT = "${android-sdk-root}";
          GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_SDK_ROOT}/build-tools/35.0.0/aapt2";
          buildInputs = [
            android-emulator
            flutter
            android-sdk
            jdk17
          ];
        };
    });
}
