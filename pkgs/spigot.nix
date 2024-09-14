{
  lib,
  mineflake,
  ...
}:
with mineflake; {
  vault = fetchFromSpigot {
    resource = 34315;
    version = 344916;
    hash = "sha256-prXtl/Q6XPW7rwCnyM0jxa/JvQA/hJh1r4s25s930B0=";
  };
}
