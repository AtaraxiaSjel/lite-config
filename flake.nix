{
  description = "A flake module to help build NixOS, nix-darwin and Home Manager configurations.";
  inputs = {
    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    call-flake.url = "github:divnix/call-flake";
  };
  outputs =
    {
      nixpkgs-lib,
      call-flake,
      self,
      ...
    }:
    let
      lib = nixpkgs-lib.lib;
      flake-lib = import ./lib { inherit lib call-flake; };
    in
    {
      flakeModules.default = lib.modules.importApply ./flake-module.nix {
        inherit (flake-lib) applyPatches;
      };
      flakeModule = self.flakeModules.default;
      lib = flake-lib;
    };
}
