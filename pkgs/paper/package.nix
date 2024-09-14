{
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "paper";
  mcVersion = "1.21.1";
  buildNum = "15";
  version = "${finalAttrs.mcVersion}-${finalAttrs.buildNum}";

  src = fetchurl {
    url = "https://papermc.io/api/v2/projects/paper/versions/${finalAttrs.mcVersion}/builds/${finalAttrs.buildNum}/downloads/paper-${finalAttrs.mcVersion}-${finalAttrs.buildNum}.jar";
    hash = "sha256-HeLQfXNKBoFnVX3Accau9mLH6NnGOmMALzrMwL6sibQ=";
  };
  dontUnpack = true;

  mojangSrc = fetchurl {
    url = "https://piston-data.mojang.com/v1/objects/59353fb40c36d304f2035d51e7d6e6baa98dc05c/server.jar";
    hash = "sha256-47xVaT6TzaAYjy5grqKBE/xkfF6FoV+j0bNHNJIxtLs=";
  };

  installPhase = ''
    install -Dm644 $src $out/server.jar
    install -Dm644 ${finalAttrs.mojangSrc} $out/cache/mojang_${finalAttrs.mcVersion}.jar
    install -Dm644 ${./eula.txt} $out/eula.txt
    install -Dm644 ${./bukkit.yml} $out/bukkit.yml
    install -Dm644 ${./spigot.yml} $out/spigot.yml
    install -Dm644 ${./commands.yml} $out/commands.yml
    install -Dm644 ${./paper-global.yml} $out/config/paper-global.yml
    install -Dm644 ${./paper-world-defaults.yml} $out/config/paper-world-defaults.yml
  '';
})
