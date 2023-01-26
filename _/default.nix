{ pkgs, npmlock2nix, ... }:
let
  npm2nix = pkgs.callPackage npmlock2nix { };
in
{
  packages.default = npm2nix.v2.build {
    src = ./.;
    # don't let npm write to fs to avoid error exit status
    buildCommands = [ "npm run build --logs-max=0 --silent --offline" ];
    installPhase = "cp -r build $out";
  };

  devShells.default = npm2nix.v2.shell {
    src = ./.;
    nativeBuildInputs = with pkgs; [ wrangler nodejs ];
  };

  tfConfig = {
    data.cloudflare_zone.kalebpaceme = {
      name = "kalebpace.me";
    };

    resource.cloudflare_record._ = {
      zone_id = "\${ data.cloudflare_zone.kalebpaceme.id }";
      name = "next";
      value = "\${ cloudflare_pages_project._.subdomain }";
      type = "CNAME";
      proxied = true;
      ttl = 1;
    };

    resource.cloudflare_pages_project._ = {
      account_id = "\${ data.cloudflare_zone.kalebpaceme.account_id }";
      name = "underscore";
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

    resource.cloudflare_pages_domain._ = {
      account_id = "\${ data.cloudflare_zone.kalebpaceme.account_id }";
      project_name = "underscore";
      domain = "next.kalebpace.me";
    };
  };
}
