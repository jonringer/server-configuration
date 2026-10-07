{
  config,
  pkgs,
  inputs,
  ...
}:
{
  services.eka-ci = {
    enable = true;
    openFirewall = false; # behind nginx reverse proxy
    dynamicUser = false; # stable UID for state directory ownership

    environmentFile = "/run/secrets/eka-ci.env";

    credentials = {
      github-app-key = "/run/secrets/eka-ci/github-app.json";
    };

    settings = {
      web = {
        address = "127.0.0.1";
        port = 3030;
        static_dir = "${config.services.eka-ci.package}/share/eka-ci/static";
        allowed_origins = [ "https://ekaci.jonringer.us" ];
      };

      security = {
        # GITHUB_WEBHOOK_SECRET provided via environmentFile
        allow_private_cache_hosts = true; # localhost:8080 cache
      };

      oauth = {
        # GITHUB_OAUTH_CLIENT_ID, GITHUB_OAUTH_CLIENT_SECRET, JWT_SECRET
        # provided via environmentFile
        redirect_url = "https://ekaci.jonringer.us/github/auth/callback";
      };

      eval = {
        timeout_secs = 3600; # 1h — corepkgs is large
        memory_limit_mb = 16384; # 16 GiB — plenty on 256G machine
        allowed_uris = [
          "https://github.com/ekala-project/"
          "https://github.com/NixOS/nixpkgs/"
          "github:ekala-project/"
          "github:NixOS/nixpkgs"
        ];
      };

      checks = {
        timeout_secs = 3600;
        memory_limit_mb = 16384;
      };

      build_no_output_timeout_seconds = 1800; # 30 min
      build_max_duration_seconds = 21600; # 6 hours
      graph_lru_capacity = 200000;
      require_approval = true; # external PR approval required

      github_apps = [
        {
          id = "production";
          credentials.systemd-credential.name = "github-app-key";
          permissions = {
            allow_all = false;
            allowed_repos = [ "ekala-project/corepkgs" ];
          };
        }
      ];

      caches = [
        {
          id = "local-cas";
          cache_type = "nix-copy";
          destination = "http://localhost:8080";
          credentials = "none";
          permissions = {
            allow_all = false;
            allowed_repos = [ "ekala-project/corepkgs" ];
          };
        }
      ];
    };
  };

  # Nginx reverse proxy with ACME TLS
  services.nginx.virtualHosts."ekaci.jonringer.us" = {
    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:3030";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_buffering off;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;

        # SSE support for live build log streaming
        proxy_set_header Connection "";
        proxy_http_version 1.1;
        chunked_transfer_encoding on;
      '';
    };
  };
}
