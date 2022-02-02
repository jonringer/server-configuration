{ config, ... }:

{
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "jonringer117@gmail.com";
  services.nginx = {
    enable = true;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    commonHttpConfig = ''
      # Add HSTS header with preloading to HTTPS requests.
      # Adding this header to HTTP requests is discouraged
      map $scheme $hsts_header {
          https   "max-age=31536000; includeSubdomains; preload";
      }
      add_header Strict-Transport-Security $hsts_header;

      # Enable CSP for your services.
      #add_header Content-Security-Policy "script-src 'self'; object-src 'none'; base-uri 'none';" always;

      # Minimize information leaked to other domains
      add_header 'Referrer-Policy' 'origin-when-cross-origin';

      # Disable embedding as a frame
      add_header X-Frame-Options DENY;

      # Prevent injection of code in other mime types (XSS Attacks)
      add_header X-Content-Type-Options nosniff;

      # Enable XSS protection of the browser.
      # May be unnecessary when CSP is configured properly (see above)
      add_header X-XSS-Protection "1; mode=block";

      # This might create errors
      proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
    '';

    virtualHosts."jonringer.us" = {
      forceSSL = true;
      enableACME = true;

      serverAliases = [ "www.jonringer.us" ];
      root = "/var/www/jonringer";
      locations."/".index = "index.html";
    };

    virtualHosts."hydra.jonringer.us" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.hydra.port}";
        proxyWebsockets = true; # needed if you need to use WebSocket
        # extraConfig =
        #   # required when the target is also TLS server with multiple hosts
        #   # "proxy_ssl_server_name on;" +
        #   # required when the server wants to use HTTP Authentication
        #   #"proxy_pass_header Authorization;"
        #   ;
      };
    };

  };
}

