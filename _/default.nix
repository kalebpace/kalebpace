{ pkgs, npmlock2nix, ... }:
let
  npm2nix = pkgs.callPackage npmlock2nix { };
in
{
  packages.default = npm2nix.v2.build {
    src = ./.;
    buildCommands = [ "npm run build" ];
    installPhase = "cp -r public $out";
  };

  devShells.default = npm2nix.v2.shell {
    src = ./.;
    nativeBuildInputs = with pkgs; [ wrangler nodejs ];
  };

  tfConfig = {
    resource.cloudflare_record._ = {
      zone_id = "\${ data.cloudflare_zone.kalebpaceme.id }";
      name = "@";
      value = "\${ cloudflare_pages_project._.subdomain }";
      type = "A";
      proxied = true;
      ttl = 1;
    };

    resource.cloudflare_pages_project._ = {
      account_id = "\${ data.cloudflare_zone.kalebpaceme.account_id }";
      name = "_";
      production_branch = "main";
    };

    resource.cloudflare_pages_domain._ = {
      account_id = "\${ data.cloudflare_zone.kalebpaceme.account_id }";
      project_name = "_";
      domain = "kalebpace.me";
    };
  };
}
