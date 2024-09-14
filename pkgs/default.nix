{
  pkgs,
  importCargo,
  ipfsGateway ? "https://w3s.link/ipfs/",
  ...
}: let
  lib = pkgs.lib;
in
  rec {
    # CLI
    mineflake = (pkgs.callPackage ../cli {inherit importCargo;}).offline;
    mineflake-online = (pkgs.callPackage ../cli {inherit importCargo;}).default;

    # Build utils
    buildMineflakeConfig = {
      type ? "spigot",
      package,
      plugins ? [],
      command ? "",
      configs ? [],
      ...
    } @ attrs:
      pkgs.writeText "mineflake.json" (builtins.toJSON (attrs
        // {
          type = type;
          package = mkMfPackage package;
          plugins = map (p: mkMfPackage p) plugins;
          command = command;
          configs = configs;
        }));

    buildMineflakeBin = config:
      pkgs.writeScriptBin "mineflake" ''
        #!${pkgs.runtimeShell}
        ${mineflake}/bin/mineflake apply -r -c "${buildMineflakeConfig config}"
      '';

    buildMineflakeContainer = config:
      pkgs.dockerTools.buildImage {
        name = "mineflake";
        tag = "latest";
        copyToRoot = buildMineflakeBin config;
        config = {
          Cmd = ["/bin/mineflake"];
          WorkingDir = "/data";
        };
      };

    buildMineflakeLayeredContainer = config:
      pkgs.dockerTools.buildLayeredImage {
        name = "mineflake";
        tag = "latest";
        contents = [(buildMineflakeBin config)];
        config = {
          Cmd = ["/bin/mineflake"];
          WorkingDir = "/data";
        };
      };

    mkMfPackage = package: {
      type = "local";
      path = package;
    };

    mkMfConfig = type: path: content: {
      type = type;
      path = path;
      content = content;
    };

    # Generates manifest.yml for a package
    buildMineflakeManifest = name: version: pkgs.writeText "mineflake-manifest.yml" (builtins.toJSON {inherit name version;});

    buildMineflakePackage = {
      pname,
      version,
      ...
    } @ attrs:
      pkgs.stdenv.mkDerivation ({
          phases = ["buildPhase" "installPhase" "manifestPhase"];
          manifestPhase = ''
            cp ${buildMineflakeManifest pname version} $out/package.yml
          '';
        }
        // attrs);

    buildZipMfPackage = {
      url,
      sha256,
      ...
    }:
      pkgs.fetchzip {inherit url sha256;};

    ipfsUrl = path: "${ipfsGateway}${path}";

    fetchFromSpigot = {
      resource,
      version,
      hash,
      ...
    }:
      pkgs.stdenvNoCC.mkDerivation {
        pname = "spigot-${builtins.toString resource}";
        version = builtins.toString version;

        src = pkgs.fetchurl {
          url = "https://api.spiget.org/v2/resources/${builtins.toString resource}/versions/${builtins.toString version}/download/proxy";
          inherit hash;
        };
        dontUnpack = true;

        installPhase = ''
          install -Dm644 $src $out/package.jar
        '';
      };

    installConfig = pkgs.writeScriptBin "installConfig" ''
      #!${lib.getExe (pkgs.python3.withPackages (ps: with ps; [pyyaml jproperties]))}
      import argparse
      import os
      import sys
      import json
      import subprocess

      parser = argparse.ArgumentParser()
      parser.add_argument(
        "files",
        metavar="FILE",
        type=str,
        nargs="+",
      )
      parser.add_argument(
        "destination",
        metavar="DESTINATION",
        type=str,
      )
      parser.add_argument(
        '-j',
        type=str,
      )
      args = parser.parse_args()

      for src in args.files:
        if src.endswith(".yml") or src.endswith(".yaml"):
          import yaml
          with open(src, "r") as f:
            data = yaml.safe_load(f)
        elif src.endswith(".properties") or src.endswith(".txt"):
          from jproperties import Properties
          p = Properties()
          with open(src, "rb") as f:
            p.load(f, "utf-8")
          data = {}
          for item in p.items():
            data[item[0]] = item[1].data
        elif src.endswith(".toml"):
          import tomllib
          with open(src, "rb") as f:
            data = tomllib.load(f)

        result = json.dumps(data, ensure_ascii=False)
        if args.j:
          j = args.j
        else:
          j = "."
        process = subprocess.Popen(
          ["${lib.getExe pkgs.jq}", j],
          stdin=subprocess.PIPE,
          stdout=subprocess.PIPE,
          text=True
        )
        result, _ = process.communicate(input=result)

        if len(args.files) == 1:
          if os.path.dirname(args.destination) != "":
            os.makedirs(os.path.dirname(args.destination), exist_ok=True)
          with open(args.destination, "w") as f:
            f.write(result)
        else:
          os.makedirs(args.destination, exist_ok=True)
          with open(os.path.join(args.destination, os.path.basename(src)), "w") as f:
            f.write(result)
    '';

    loadConfigs = let
      listFilesRecursive = dir: dirName:
        lib.flatten (lib.mapAttrsToList (
          name: type:
            if type == "directory"
            then listFilesRecursive "${dir}/${name}" "${dirName}${name}/"
            else "${dirName}${name}"
        ) (builtins.readDir dir));
    in
      dir:
        builtins.listToAttrs (map (file: {
          name = file;
          value = {
            data = builtins.fromJSON (builtins.readFile "${dir}/mf/${file}");
          };
        }) (listFilesRecursive "${dir}/mf" ""));
  }
  // (let
    makePackages = dir:
      lib.mapAttrs
      (name: _: pkgs.callPackage (dir + "/${name}/package.nix") {})
      (lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir));
  in
    makePackages ./.)
  // (pkgs.callPackage ./spigot.nix {})
