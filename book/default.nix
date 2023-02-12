{}:
{
  packages = { default = null; };
  devShells = { default = null; };
  tfConfig = {
    resource.cloudflare_record.book = {
      zone_id = "\${ data.cloudflare_zone.kalebpaceme.id }";
      name = "book";
      value = "100::";
      type = "AAAA";
      proxied = true;
      ttl = 1;
    };
  };
}
