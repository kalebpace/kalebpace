{ pkgs, npmlock2nix, ... }:
let
  npm2nix = pkgs.callPackage npmlock2nix { };
in
{
  # packages.default = npm2nix.v1.build {
  #   src = ./_layouts;
  #   buildCommands = [ "HOME=. npm run build" ];
  #   installPhase = "cp -r public $out";
  #   node_modules_mose = "copy";
  # };

  devShells.default = npm2nix.v1.shell {
    src = ./_layouts;
    nativeBuildInputs = with pkgs; [ wrangler ];
  };

  tfConfig = {
    resource.cloudflare_record.know = {
      zone_id = "\${ data.cloudflare_zone.kalebpaceme.id }";
      name = "know";
      value = "\${ cloudflare_pages_project.know.subdomain }";
      type = "CNAME";
      ttl = 3600;
    };

    resource.cloudflare_pages_project.know = {
      account_id = "\${ data.cloudflare_zone.kalebpaceme.account_id }";
      name = "know";
      production_branch = "main";
    };

    resource.cloudflare_pages_domain.know = {
      account_id = "\${ data.cloudflare_zone.kalebpaceme.account_id }";
      project_name = "know";
      domain = "know.kalebpace.me";
    };
  };
}
