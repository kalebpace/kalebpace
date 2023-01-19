{ pkgs, ...}:
let
  cgitrc = (pkgs.writeTextDir "/etc/cgitrc" ''${builtins.readFile ./cgitrc}'');
  nginxConf = (pkgs.writeTextDir "/etc/nginx/nginx.conf" ''${builtins.readFile ./nginx.conf}'');
in
{
  packages.default = pkgs.dockerTools.buildImage {
    # fromImage = (pkgs.dockerTools.pullImage {
    #   imageName = "ubuntu"; #stable-slim
    #   imageDigest = "sha256:965fbcae990b0467ed5657caceaec165018ef44a4d2d46c7cdea80a9dff0d1ea";
    #   sha256 = "sha256-P7EulEvNgOyUcHH3fbXRAIAA3afHXx5WELJX7eNeUuM=";
    # });

    name = "cgit";
    tag = "latest";

    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      paths = with import <nixpkgs> { system = "x86_64-linux"; }; [
        pkgs.fakeNss
        coreutils
        bash
        cgit
        cgitrc
        nginx
        nginxConf
        fcgiwrap
        socat
      ];
      pathsToLink = [ "/bin" "/cgit" "/etc" "/etc/nginx/fastcgi_params" "/var" "/lib" "/var/log/nginx" "/var/www/html/cgit/cgi" "/run" "/usr" ];
    };

    extraCommands = ''
      mkdir -p tmp/nginx_client_body
    '';

    config = {
      Cmd = [ "socat UNIX-LISTEN:/run/fcgiwrap.socket UNIX-SENDTO:/cgit/cgit.cgi & nginx -c /etc/nginx/nginx.conf" ];
      Env = [ "USER=nobody" ];
      ExposedPorts = {
        "22/tcp" = { };
      };
    };
  };
  
  tfConfig = import ./config.nix;
}
