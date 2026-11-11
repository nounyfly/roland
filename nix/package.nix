{ inputs, pkgs, ... }:
let
  craneLib = inputs.crane.mkLib pkgs;
  commonArgs = {
    src = craneLib.cleanCargoSource ../.;
    strictDeps = true;
    nativeBuildInputs = [
      pkgs.pkg-config
    ];
    buildInputs = with pkgs; [
      libinput
      libnotify
    ];
    runtimeDependencies = with pkgs; [
      libinput
      libnotify
      niri
    ];
  };
in
craneLib.buildPackage (
  commonArgs
  // {
    cargoArtifacts = craneLib.buildDepsOnly commonArgs;

    meta = {
      mainProgram = "roland";
    };
  }
)
