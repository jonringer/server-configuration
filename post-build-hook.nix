{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.queued-build-hook.nixosModules.queued-build-hook ];

  queued-build-hook = {
    enable = true;
    postBuildScriptContent = ''
      set -euo pipefail
      # OUT_PATHS is set by Nix to space-separated output store paths.
      # Word splitting is intentional here.
      # shellcheck disable=SC2086
      ${config.nix.package}/bin/nix store sign --recursive --key-file "''${CREDENTIALS_DIRECTORY}/binary-cache-key" $OUT_PATHS
      # Push to cachix
      # shellcheck disable=SC2086
      ${pkgs.cachix}/bin/cachix push ekala-corepkgs $OUT_PATHS
      # Push to local ekapkgs CAS cache.
      # shellcheck disable=SC2086
      ${pkgs.ekapkgs}/bin/ekapkgs cache push $OUT_PATHS
    '';
    credentials = {
      binary-cache-key = "/var/cache-priv-key.pem";
    };
  };

  systemd.services.async-nix-post-build-hook = {
    serviceConfig.EnvironmentFile = [
      "/var/lib/cachix/env"
    ];
  };
}
