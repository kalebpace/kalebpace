{ pkgs ? import <nixpkgs> { } }:
let
  # nginxPort = "80";
  sshPort = "22";

  # nginxConf = pkgs.writeText "nginx.conf" ''
  #   user nobody nobody;
  #   daemon off;
  #   error_log /dev/stdout info;
  #   pid /dev/null;
  #   events {}
  #   http {
  #     access_log /dev/stdout;
  #     server {
  #       listen ${nginxPort};
  #       index index.html;
  #       location / {
  #         root ${nginxWebRoot};
  #       }
  #     }
  #   }
  # '';

  # nginxWebRoot = pkgs.writeTextDir "index.html" ''
  #   <html><body><h1>Hello from NGINX</h1></body></html>
  # '';

  # gitwebNginxConf = pkgs.writeTextFile {
  #   name = "gitweb";
  #   text = ''
  #     server {
  #       # Git repos are browsable at http://example.com:4321/
  #       listen 4321 default;   # Remove 'default' from this line if there is already another server running on port 80
  #       server_name example.com;

  #       location /index.cgi {
  #         root /usr/share/gitweb/;
  #         include fastcgi_params;
  #         gzip off;
  #         fastcgi_param SCRIPT_NAME $uri;
  #         fastcgi_param GITWEB_CONFIG /etc/gitweb.conf;
  #         fastcgi_pass  unix:/var/run/fcgiwrap.socket;
  #       }

  #       location / {
  #         root /usr/share/gitweb/;
  #         index index.cgi;
  #       }
  #     }
  #   '';
  #   executable = true;
  #   destination = "/etc/nginx/sites-enabled/gitweb";
  # };

  pkgsContainerArch = import <nixpkgs> { system = "x86_64-linux"; };
in
pkgs.dockerTools.buildLayeredImage {
  name = "gitweb";
  tag = "latest";

  contents = with pkgsContainerArch; [
    busybox
    git
    # gitwebNginxConf
    nginx
    openssh
    pkgs.dockerTools.fakeNss
    coreutils
  ];

  extraCommands = ''
    # mkdir -p tmp/nginx_client_body
    # nginx still tries to read this directory even if error_log
    # directive is specifying another file :/
    # mkdir -p var/log/nginx
    
    adduser -G git git
  '';

  config = {
    # Cmd = [ "nginx" "-c" nginxConf ];
    ExposedPorts = {
      # "${nginxPort}/tcp" = { };
      "${sshPort}/tcp" = { };
    };
  };
}
