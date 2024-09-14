{pkgs ? import <nixpkgs> {}}: let
  # We don't want to make new dependencies in flakes, so we use the
  # fetchers from nixpkgs.
  rust-overlay = import (pkgs.fetchFromGitHub {
    owner = "oxalica";
    repo = "rust-overlay";
    rev = "cf668f737ac986c0a89e83b6b2e3c5ddbd8cf33b";
    sha256 = "sha256-bVuzLs1ZVggJAbJmEDVO9G6p8BH3HRaolK70KXvnWnU=";
  });
  pkgs' = pkgs.extend rust-overlay;
in
  pkgs.mkShell {
    nativeBuildInputs = with pkgs; [nixpkgs-fmt pkg-config];
  }
