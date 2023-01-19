{ pkgs, ... }:
let
  buildInputs = with pkgs; [
    wrangler
    nodejs
  ];
in
with pkgs;
{
  packages.default = stdenv.mkDerivation {
    name = "know";
    inherit buildInputs;
    installPhase = ''
      cd _layouts
      ${nodejs}/bin/npm install && npm build
      cp -r ./public $out/
    '';
  };

  devShells.default = mkShell {
    packages = buildInputs;
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
  };
}
