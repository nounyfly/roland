{
  description = "Roland packaging for nix";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    crane.url = "github:ipetkov/crane";
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.home-manager.flakeModules.home-manager
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          packages.default = self'.packages.roland;
          packages.roland = pkgs.callPackage ./nix/package.nix { inherit inputs; };
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.
        };
      flake = {
        homeModules.default = {
          config, lib, pkgs, ...
        }:
        {
          options.services.roland = {
            enable = lib.mkEnableOption "roland";
            settings = lib.mkOption {
              type = lib.types.attrs;
              default = {};
            };
            package = lib.mkOption {
              type = lib.types.package;
              default = null;
            };
          };


          config = lib.mkIf config.services.roland.enable {
            home.packages = [
              config.services.roland.package
            ];
            systemd.user.services.roland =
            let
              configFile = pkgs.writers.writeTOML "roland-config" config.services.roland.settings;
              args = "--config ${configFile}";
            in
            {
              Unit = {
                Description = "Cute kitties to sync with your frens :3";
                PartOf = [ config.wayland.systemd.target ];
                After = [ config.wayland.systemd.target ];
              };
              Install.WantedBy = [config.wayland.systemd.target];
              Service.ExecStart = "${lib.getExe config.services.roland.package} ${args}";
            };
          };
        };
      };
    };
}
