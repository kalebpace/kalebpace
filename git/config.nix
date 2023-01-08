{ config, ... }:
let
  secrets = (import ./secrets.nix) { };
in
{
  terraform.required_providers = {
    neon = {
      source = "kislerdm/neon";
    };

    fly = {
      source = "fly-apps/fly";
    };
  };

  provider = {
    neon = {
      api_key = secrets.NEON_API_KEY;
    };

    fly = {
      fly_api_token = secrets.FLY_API_TOKEN;
      useinternaltunnel = true;
      internaltunnelorg = "personal";
      internaltunnelregion = "dfw";
    };
  };

  resource.neon_project.gitea = {
    name = "gitea";
  };

  resource.fly_app.gitea = {
    name = "snowflake-megaphone-hovercraft";
  };

  resource.fly_ip.gitea-ipv4 = {
    app = "\${ fly_app.gitea.name }";
    type = "v4";
  };

  resource.fly_ip.gitea-ipv6 = {
    app = "\${ fly_app.gitea.name }";
    type = "v6";
  };

  resource.fly_machine.gitea = {
    app = "\${ fly_app.gitea.name }";
    region = "dfw";
    image = "gitea/gitea:1.18";
    memorymb = 1024;

    env = {
      GITEA__database__DB_TYPE = "postgres";
      GITEA__database__HOST = "\${ neon_project.gitea.database_host }";
      GITEA__database__NAME = "\${ neon_project.gitea.database_name }";
      GITEA__database__PASSWD = "\${ neon_project.gitea.database_password }";
      GITEA__database__USER = "\${ neon_project.gitea.database_user }";
      GITEA__server__ROOT_URL = "\${ fly_ip.gitea-ipv4.address }";
    };

    services = [
      {
        ports = [
          {
            port = 80;
            handlers = [ "http" ];
          }
        ];
        protocol = "tcp";
        internal_port = "3000";
      }
    ];

    mounts = [
      {
        path = "/data";
        volume = config.resource.fly_volume.gitea.name;
      }
    ];
  };

  resource.fly_volume.gitea = {
    name = "gitea_data";
    app = "\${ fly_app.gitea.name }";
    size = 1;
    region = config.resource.fly_machine.gitea.region;
  };
}
