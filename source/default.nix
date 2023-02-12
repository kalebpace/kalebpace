{ pkgs,pkgs-x86_64-linux, ... }:
let
  cgitrc = (pkgs.writeTextDir "/etc/cgitrc" ''${builtins.readFile ./cgitrc}'');
  nginxConf = (pkgs.writeTextDir "/etc/nginx/nginx.conf" ''${builtins.readFile ./nginx.conf}'');
in
with pkgs;
rec {
  packages.default = dockerTools.buildImage {
    name = "cgit";
    tag = "latest";

    copyToRoot = buildEnv {
      name = "image-root";
      paths = with pkgs-x86_64-linux; [
        pkgs.fakeNss
        coreutils
        bash
        cgit
        cgitrc
        nginx
        nginxConf
        fcgiwrap
        spawn_fcgi
      ];
      pathsToLink = [ "/bin" "/cgit" "/etc" "/etc/nginx/fastcgi_params" "/var" "/lib" "/var/log/nginx" "/var/www/html/cgit/cgi" "/run" "/usr" ];
    };

    extraCommands = ''
      mkdir -p tmp/nginx_client_body
    '';

    config = {
      Cmd = ["exec /usr/bin/spawn-fcgi -n -s /run/fcgiwrap.sock -u 1000 -U www-data -- /cgit/cgit.cgi" "&" "nginx -c /etc/nginx/nginx.conf" ];
      Env = [ "USER=nobody" ];
      ExposedPorts = {
        "22/tcp" = { };
      };
    };
  };
  
  tfConfig = import ./config.nix;
}
