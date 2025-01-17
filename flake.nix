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
      android-comp = pkgs.androidenv.composeAndroidPackages {
        buildToolsVersions = [ "34.0.0" ];
        platformVersions = [ "33" "34" "35" ];
      };
      android-sdk = android-comp.androidsdk;
      android-sdk-root = "${android-sdk}/libexec/android-sdk";
    in
    {
      devShell =
        with pkgs; mkShell rec {
          ANDROID_SDK_ROOT = "${android-sdk-root}";
          GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_SDK_ROOT}/build-tools/34.0.0/aapt2";
          buildInputs = [
            flutter
            android-sdk
            jdk17
          ];
        };
    });
}
