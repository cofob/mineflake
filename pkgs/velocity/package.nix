{
  stdenv,
  fetchgit,
  gradle_8,
  git,
  mineflake,
  jdk17,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "velocity";
  version = "415";

  src = fetchgit {
    url = "https://github.com/PaperMC/Velocity.git";
    leaveDotGit = true;
    rev = "00ed2284ecb4fb03bbb97d2b6a62c61ab15cde1a";
    hash = "sha256-bekr9omGxN5jmLEgw8fGHxQGR06gu7o8fywW3lK88JU=";
  };

  nativeBuildInputs = [
    gradle_8
    git
    mineflake.installConfig
  ];

  mitmCache = gradle_8.fetchDeps {
    pkg = mineflake.velocity;
    data = ./deps.json;
  };
  __darwinAllowLocalNetworking = true;

  gradleFlags = ["-Dorg.gradle.java.home=${jdk17}"];
  gradleBuildTask = "shadowJar";

  passthru.mf.configs = mineflake.loadConfigs finalAttrs.finalPackage;

  installPhase = ''
    install -Dm644 ./proxy/build/libs/velocity-proxy-3.3.0-SNAPSHOT-all.jar $out/server.jar

    installConfig ./proxy/src/main/resources/com/velocitypowered/proxy/l10n/* $out/mf/lang/
    installConfig ./proxy/src/main/resources/default-velocity.toml $out/mf/velocity.toml -j '.forced-hosts = {} | .servers = {"try": []}'
    installConfig ${./bstats.txt} $out/mf/plugins/bStats/config.txt
  '';
})
