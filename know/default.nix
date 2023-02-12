{ pkgs, npmlock2nix, ... }:
let
  npm2nix = pkgs.callPackage npmlock2nix { };
in
rec
{
  packages = rec {
    default = npm2nix.v2.build {
      src = ./_layouts;
      nativeBuildInputs = [ pkgs.sysctl ];
      buildInputs = [ content ];
      buildCommands = [ "HOME=/tmp npm run build --slient --offline" ];
      installPhase = "cp -r public $out";
      node_modules_mode = "copy";
    };

    content = pkgs.stdenv.mkDerivation {
      name = "content";
      src = ./content;
      installPhase = "mkdir $out && cp -r . $out";
    };
  };

  devShells.default = npm2nix.v2.shell {
    src = ./_layouts;
    nativeBuildInputs = with pkgs; [ wrangler ];
  };

  tfConfig = {
    resource.cloudflare_record.know = {
      zone_id = "\${ data.cloudflare_zone.kalebpaceme.id }";
      name = "know";
      value = "\${ cloudflare_pages_project.know.subdomain }";
      type = "CNAME";
      proxied = true;
      ttl = 1;
    };

    resource.cloudflare_pages_project.know = {
      account_id = "\${ data.cloudflare_zone.kalebpaceme.account_id }";
      name = "know";
      production_branch = "main";
      deployment_configs = {
        preview = {
          always_use_latest_compatibility_date = true;
          fail_open = false;
          usage_model = "bundled";
        };
        production = {
          compatibility_date = "2023-01-20";
          fail_open = false;
          usage_model = "bundled";
        };
      };
    };

    resource.cloudflare_pages_domain.know = {
      account_id = "\${ data.cloudflare_zone.kalebpaceme.account_id }";
      project_name = "know";
      domain = "know.kalebpace.me";
    };
  };
}
