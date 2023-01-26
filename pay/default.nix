{ pkgs, secrets, ... }:
let
  buildInputs = with pkgs; [
    wrangler
  ];
in
with pkgs;
{
  packages.default = stdenv.mkDerivation {
    name = "pay";
    src = builtins.filterSource (path: type: baseNameOf path != "default.nix") ./.;
    inherit buildInputs;
    installPhase = ''
      mkdir -p $out
      cp -r ./ $out
    '';
  };

  devShells.default = mkShell {
    packages = buildInputs;
  };

  tfConfig = {
    resource.cloudflare_record.pay = {
      zone_id = "\${ data.cloudflare_zone.kalebpaceme.id }";
      name = "pay";
      value = "\${ cloudflare_pages_project.pay.subdomain }";
      type = "CNAME";
      proxied = true;
      ttl = 1;
    };

    resource.cloudflare_pages_project.pay = {
      account_id = "\${ data.cloudflare_zone.kalebpaceme.account_id }";
      name = "pay";
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

    resource.cloudflare_pages_domain.pay = {
      account_id = "\${ data.cloudflare_zone.kalebpaceme.account_id }";
      project_name = "pay";
      domain = "pay.kalebpace.me";
    };
  };
}
