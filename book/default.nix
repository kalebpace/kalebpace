{}:
{
  tfConfig = {
    resource.cloudflare_record.book = {
      zone_id = "\${ data.cloudflare_zone.kalebpaceme.id }";
      name = "book";
      value = "100::";
      type = "AAAA";
      proxied = true;
      ttl = 1;
    };

    resource.cloudflare_ruleset.book = {
      zone_id = "\${ data.cloudflare_zone.kalebpaceme.id }";
      name = "book";
      kind = "zone";
      phase = "http_request_dynamic_redirect";

      rules = {
        action = "redirect";
        action_parameters = {
          from_value = {
            status_code = 302;
            target_url = {
              value = "https://cal.com/kalebpace";
            };
          };
        };
        expression = "(http.request.full_uri contains \"book.kalebpace.me\")";
        description = "Redirect from book.kalebpace.me to cal.com/kalebpace";
        enabled = true;
      };
    };
  };
}
