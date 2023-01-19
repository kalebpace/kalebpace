{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    terranix.url = "github:terranix/terranix";
  };

  outputs = { self, nixpkgs, utils, terranix, ... }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        secrets = import ./secrets.nix { };

        projects = {
          _ = import ./_ { inherit pkgs; };
          git = import ./git { inherit pkgs; };
          know = import ./know { inherit pkgs; };
          pay = import ./pay { inherit pkgs; };
        };

        tfConfig = terranix.lib.terranixConfiguration {
          inherit system;
          modules = [
            (import ./config.nix {
              inherit secrets;
            })
          ] ++ builtins.concatMap (p: [ p.tfConfig ]) projects;
        };
      in
      rec {
        packages = {
          know = projects.know.packages.default;
        };

        devShells = {
          know = projects.know.devShells.default;
          default = with pkgs; mkShell {
            buildInputs = [
              (vscode-with-extensions.override {
                vscode = vscodium;
                vscodeExtensions = with vscode-extensions; [
                  jnoortheen.nix-ide
                  viktorqvarfordt.vscode-pitch-black-theme
                  asvetliakov.vscode-neovim
                  foam.foam-vscode
                  svelte.svelte-vscode
                  tamasfe.even-better-toml
                ];
              })
            ];
          };
        };

        apps = rec {
          # nix run
          default = apply;

          # nix run ".#apply"
          apply = {
            type = "app";
            program = toString (pkgs.writers.writeBash "apply" ''
              if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
              cp ${tfConfig} config.tf.json \
                && ${pkgs.terraform}/bin/terraform init \
                && ${pkgs.terraform}/bin/terraform apply
            '');
          };

          # nix run ".#destroy"
          destroy = {
            type = "app";
            program = toString (pkgs.writers.writeBash "destroy" ''
              if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
              cp ${tfConfig} config.tf.json \
                && ${pkgs.terraform}/bin/terraform init \
                && ${pkgs.terraform}/bin/terraform destroy
            '');
          };
        };
      }
    );
}
