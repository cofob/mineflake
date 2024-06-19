{ pkgs ? import <nixpkgs> { } }:

let
  # We don't want to make new dependencies in flakes, so we use the
  # fetchers from nixpkgs.
  rust-overlay = import (pkgs.fetchFromGitHub {
    owner = "oxalica";
    repo = "rust-overlay";
    rev = "69fcfaebbe564d162a85cadeaadd4dec646be4a2";
    sha256 = "sha256-JHqQyO5XppLpMSKBaYlxbmPHMc4DpwuavKIch9W+hv4=";
  });
  pkgs' = pkgs.extend rust-overlay;
in
pkgs'.mkShell {
  nativeBuildInputs = with pkgs'; [ rust-bin.stable.latest.default nixpkgs-fmt ];
}
