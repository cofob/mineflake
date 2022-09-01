{
  description = "Minecraft server in Nix";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    {
      nixosModules.default = import ./modules/mineflake.nix;

      overlays.default = final: prev: {
        mineflake = import ./pkgs {
          pkgs = prev;
          lib = prev.lib;
        };
      };
    };
}
