{ config, ... }:
{
  resource.fly_app.git = {
    name = "snowflake-megaphone-hovercraft";
  };

  resource.fly_ip.git-ipv4 = {
    app = "\${ fly_app.git.name }";
    type = "v4";
  };

  resource.fly_ip.git-ipv6 = {
    app = "\${ fly_app.git.name }";
    type = "v6";
  };

  resource.fly_machine.git = {
    app = "\${ fly_app.git.name }";
    region = "dfw";
    image = "";

    env = {

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
        path = "/var/lib/git";
        volume = config.resource.fly_volume.git.name;
      }
    ];
  };

  resource.fly_volume.git = {
    name = "git_data";
    app = "\${ fly_app.git.name }";
    size = 1;
    region = config.resource.fly_machine.git.region;
  };
}
