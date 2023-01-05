{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    nix-git-hooks.url = "github:ysndr/nix-git-hooks";
  };

  outputs = { self, nixpkgs, utils, nix-git-hooks }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ nix-git-hooks.overlay ];
        };

        vscodeWithExtensions = with pkgs;
          (vscode-with-extensions.override {
            vscode = vscodium;
            vscodeExtensions = with vscode-extensions; [
              jnoortheen.nix-ide
              viktorqvarfordt.vscode-pitch-black-theme
              asvetliakov.vscode-neovim
            ];
          });

        wranglerPublishPrePush = with pkgs; pkgs.writeShellScriptBin "wrangler-publish" ''
          ${wrangler}/bin/wrangler pages publish ./pay --project-name pay --branch main
          RESULT=$?
          [ $RESULT != 0 ] && echo "Failed to publish to cloudflare, try running again..."
          exit $RESULT
        '';

        hookInstaller = pkgs.git-hook-installer { pre-push = [ wranglerPublishPrePush ]; };
        hookUninstaller = pkgs.git-hook-uninstaller;
      in
      rec {
        devShell = with pkgs; (mkShell.override { stdenv = pkgs.stdenv; } {
          buildInputs = [
            vscodeWithExtensions
            wrangler
          ];
          packages = [hookInstaller hookUninstaller];
          shellHook = ''
            install-git-hooks
          '';
        });
      }
    );
}
