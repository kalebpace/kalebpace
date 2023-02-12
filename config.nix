{secrets, ...}:
{
  provider = {
    cloudflare = {
      api_token = secrets.CF_API_TOKEN;
    };

    fly = {
      fly_api_token = secrets.FLY_API_TOKEN;
      useinternaltunnel = true;
      internaltunnelorg = "personal";
      internaltunnelregion = "dfw";
    };
  };
  
  terraform.required_providers = {
    cloudflare = {
      source = "cloudflare/cloudflare";
      version = "~> 3.0";
    };

    fly = {
      source = "fly-apps/fly";
    };
  };
  
  data.cloudflare_zone.kalebpaceme = {
    name = "kalebpace.me";
  };
}