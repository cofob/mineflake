{
  lib,
  maven,
  fetchgit,
  mineflake,
}:
maven.buildMavenPackage rec {
  pname = "bungeecord";
  version = "1858";

  src = fetchgit {
    url = "https://github.com/SpigotMC/BungeeCord.git";
    fetchSubmodules = true;
    rev = "cd56fb32c207b39b9470d66d7c61f68d9f0c7e78";
    sha256 = "sha256-pD0ZQRIYNJuohcnj6lKnOaALMiSB6yj/Arz/reu2qSM=";
  };

  mvnHash = "sha256-7vcVC/TZwiAQh38i7c9YK/ef1hj/v/d3mprFqiCYch4=";

  nativeBuildInputs = [mineflake.installConfig];

  installPhase = ''
    install -Dm644 ./bootstrap/target/BungeeCord.jar $out/server.jar
    ${lib.concatMapStrings (name: ''
      install -Dm644 ./module/cmd-${name}/target/cmd_${name}.jar $out/modules/cmd_${name}.jar
    '') ["alert" "find" "list" "send" "server"]}
    install -Dm644 ./module/reconnect-yaml/target/reconnect_yaml.jar $out/modules/reconnect_yaml.jar
  '';
}
