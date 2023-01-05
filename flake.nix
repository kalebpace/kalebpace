{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        vscodeWithExtensions = with pkgs;
          (vscode-with-extensions.override {
            vscode = vscodium;
            vscodeExtensions = with vscode-extensions; [
              jnoortheen.nix-ide
              viktorqvarfordt.vscode-pitch-black-theme
              asvetliakov.vscode-neovim
            ];
          });
      in
      rec {
        devShell = with pkgs; (mkShell.override { stdenv = pkgs.stdenv; } {
          buildInputs = [
            vscodeWithExtensions
            wrangler
          ];
        });
      }
    );
}
