{ pkgs, ... }:
let
  buildInputs = with pkgs; [
    wrangler
  ];
in
with pkgs;
{
  packages.default = stdenv.mkDerivation {
    name = "pay";
    inherit buildInputs;
    installPhase = ''
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
      ttl = 3600;
    };

    resource.cloudflare_pages_project.pay = {
      account_id = "\${ data.cloudflare_zone.kalebpaceme.account_id }";
      name = "pay";
      production_branch = "main";
    };
  };
}
