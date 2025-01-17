{
description = "Flutter 3.13.x";
inputs = {
  nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";
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
      androidSdk = pkgs.androidenv.androidPkgs_9_0.androidsdk;
    in
    {
      devShell =
        with pkgs; mkShell rec {
          ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          buildInputs = [
            flutter
            androidSdk
            jdk17
          ];
        };
    });
}
