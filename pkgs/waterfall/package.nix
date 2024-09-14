{
  lib,
  stdenvNoCC,
  fetchgit,
  git,
  maven,
  mineflake,
}: let
  patchedSrc = stdenvNoCC.mkDerivation {
    pname = "waterfall-src";
    version = "579";

    src = fetchgit {
      url = "https://github.com/PaperMC/Waterfall.git";
      fetchSubmodules = true;
      rev = "f321a45a051d78a3aa86ce3507b18ce2d6251c71";
      sha256 = "sha256-8eBkBHUVHMwLzB8cLtr490Sy/H52pzQEWc7/Gm6Hzr8=";
    };

    nativeBuildInputs = [git];

    patchPhase = ''
      patchShebangs scripts/applyPatches.sh
    '';

    buildPhase = ''
      export HOME=$(mktemp -d)
      git config --global user.email "no-reply@nixos.org"
      git config --global user.name "Nix Build"

      cd BungeeCord
      git init
      git add --all
      git commit -m "Initial commit"
      cd ..

      ./scripts/applyPatches.sh
    '';

    installPhase = ''
      cp -R ./ $out/
    '';
  };
in
  maven.buildMavenPackage rec {
    pname = "waterfall";
    version = src.version;

    src = patchedSrc;

    mvnHash = "sha256-LuYF6X53mJO/uCxDtpH5i8W7xeAYxQkS8IovsIJrYjI=";

    nativeBuildInputs = [mineflake.installConfig];

    installPhase = ''
      install -Dm644 ./Waterfall-Proxy/bootstrap/target/Waterfall.jar $out/server.jar
      ${lib.concatMapStrings (name: ''
        install -Dm644 ./Waterfall-Proxy/module/cmd-${name}/target/cmd_${name}.jar $out/modules/cmd_${name}.jar
      '') ["alert" "find" "list" "send" "server"]}
      install -Dm644 ./Waterfall-Proxy/module/reconnect-yaml/target/reconnect_yaml.jar $out/modules/reconnect_yaml.jar

      installConfig ${./config.yml} $out/mf/config.yml \
        -j '.disabled_commands = [] | .servers = {} | .listeners = [] | .groups = {} | .stats = "00000000-0000-0000-0000-000000000000"'
      installConfig ${./waterfall.yml} $out/mf/waterfall.yml
    '';
  }
