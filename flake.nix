{
  description = "Minecraft server in Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    import-cargo.url = "github:edolstra/import-cargo";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    import-cargo,
    flake-utils,
  }:
    {
      overlays = rec {
        mineflake = final: prev: {
          mineflake = import ./pkgs {
            pkgs = prev;
            inherit (import-cargo.builders) importCargo;
          };
        };

        mineflakeWithCustomAttrs = attrs: final: prev: {
          mineflake = import ./pkgs ({
              pkgs = prev;
              inherit (import-cargo.builders) importCargo;
            }
            // attrs);
        };

        default = mineflake;
      };

      templates = rec {
        docker = {
          path = ./templates/docker;
          description = "An example of a mineflake docker container";
          welcomeText = ''
            This is an example of a mineflake docker container.

            You can use it to deploy your own minecraft server
            on any machine that supports Docker.

            To use it, run:

              $ nix build .

              $ docker load < result

              $ docker run --rm -it -p 25565:25565 mineflake

            Then, edit the docker.nix file to your liking.
          '';
        };
        default = docker;
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [self.overlays.default];
        };
        overlay = (self.overlays.default pkgs pkgs).mineflake;
      in {
        devShells.default = import ./shell.nix {inherit pkgs;};

        packages = let
          buildInputs = builtins.filter (p: p ? outPath) (builtins.attrValues overlay);
          namedInputs =
            builtins.listToAttrs
            (
              map
              (p: {
                name = p.name;
                value = p.outPath;
              })
              buildInputs
            );
        in (overlay
          // {
            # This is a hack to get the buildInputs of the overlay
            # Used for caching on cachix
            default = pkgs.stdenvNoCC.mkDerivation {
              name = "all";
              src = ./.;
              buildInputs = buildInputs;
              installPhase = "mkdir -p $out; cp ${pkgs.writeText "packages" (builtins.toJSON namedInputs)} $out/buildInputs";
            };
          });

        apps = rec {
          mineflake = {
            type = "app";
            program = "${overlay.mineflake}/bin/mineflake";
          };
          default = mineflake;
        };
      }
    );
}
