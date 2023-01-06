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
              graphql.vscode-graphql
            ];
          });

        wranglerPublishPrePush = with pkgs; pkgs.writeShellScriptBin "wrangler-publish" ''
            current_branch=$(git rev-parse --abbrev-ref --symbolic-full-name HEAD)
            if [ "$current_branch" != "main" ]; then
              echo "Not on main branch, skipping wrangler publish"
              exit
            fi

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
          packages = [ hookInstaller hookUninstaller ];
          shellHook = ''
            install-git-hooks
          '';
        });
      }
    );
}
