{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
# Snix binary cache served via nar-bridge at cache.jonringer.us.
#
# The snix store daemon holds content-addressed data on ZFS
# (/tank/nixstore). A post-build-hook signs and copies every build
# output into the store, and nar-bridge exposes it over the Nix
# HTTP Binary Cache protocol on port 9000 (nginx proxies to it).

let
  cfg = config.services.snix;

  # Best-effort snix build. If this fails (missing/wrong Cargo.lock hashes,
  # protobuf gen issues, feature drift, etc.), override:
  #   services.snix.package = pkgs.callPackage ./snix-local.nix {};
  defaultSnixPackage = pkgs.callPackage ./snix-package.nix {
    # snix-package.nix imports the depot root (default.nix at the top of
    # the snix repo), which then exposes `.snix.crates.workspaceMembers`.
    snixSrc = inputs.snix;
  };

  # Directory layout — blob/metadata storage on ZFS for capacity.
  castoreDir = "/tank/nixstore/snix-castore";
  storeDir = "/tank/nixstore/snix-store";
  runtimeDir = "/run/snix";

  # The daemon-side socket that the CLI/mount use to talk to the store daemon.
  storeGrpcSocket = "${runtimeDir}/store.sock";

  # Post-build hook script: signs every build output and pushes to cachix.
  # When snix is enabled, also copies into the snix store for nar-bridge.
  # Executed by queued-build-hook daemon asynchronously (not blocking nix-daemon).
  postBuildScript = ''
    set -euo pipefail
    # OUT_PATHS is set by Nix to space-separated output store paths.
    # Word splitting is intentional here.
    # shellcheck disable=SC2086
    ${config.nix.package}/bin/nix store sign --recursive --key-file "''${CREDENTIALS_DIRECTORY}/binary-cache-key" $OUT_PATHS
  '' + lib.optionalString cfg.enable ''
    export BLOB_SERVICE_ADDR="grpc+unix:${storeGrpcSocket}"
    export DIRECTORY_SERVICE_ADDR="grpc+unix:${storeGrpcSocket}"
    export PATH_INFO_SERVICE_ADDR="grpc+unix:${storeGrpcSocket}"
    # nix path-info outputs a JSON object keyed by path; snix-store copy
    # expects a JSON array. Use jq to convert.
    # shellcheck disable=SC2086
    ${config.nix.package}/bin/nix path-info --json --json-format 1 --recursive $OUT_PATHS \
      | ${pkgs.jq}/bin/jq '[to_entries[] | .value + {path: .key}]' \
      | ${cfg.package}/bin/snix-store copy -
  '' + ''
    # Push to Cachix binary cache.
    # shellcheck disable=SC2086
    ${pkgs.cachix}/bin/cachix push ekala-corepkgs $OUT_PATHS
  '';

in {
  options.services.snix = {
    enable = lib.mkEnableOption "snix binary cache (store daemon + nar-bridge)";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultSnixPackage;
      defaultText = lib.literalMD "built from `inputs.snix` via `rustPlatform.buildRustPackage`";
      description = "The snix package providing snix-store, nix-daemon, and snix binaries.";
    };

    useSubstituter = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Add cache.snix.dev to nix substituters (recommended, saves rebuilding snix).";
    };
  };

  config = lib.mkMerge [
    # Always active: async post-build-hook for signing + cachix push.
    # The postBuildScript conditionally includes snix-store copy only when
    # services.snix.enable is true.
    {
      queued-build-hook = {
        enable = true;
        postBuildScriptContent = postBuildScript;
        credentials = {
          binary-cache-key = "/var/cache-priv-key.pem";
        };
      };

      systemd.services.async-nix-post-build-hook = {
        serviceConfig.EnvironmentFile = "/var/lib/cachix/env";
      };
    }

    # Snix-specific config: store daemon, nar-bridge, ordering deps, CLI tools.
    (lib.mkIf cfg.enable {
      # Ensure the async hook daemon waits for the snix store socket.
      systemd.services.async-nix-post-build-hook = {
        after = [ "snix-store-daemon.service" ];
        requires = [ "snix-store-daemon.service" ];
      };

      # Expose snix CLI tools on $PATH.
      environment.systemPackages = [
        (pkgs.runCommand "snix-user-bins" { } ''
          mkdir -p $out/bin
          ln -s ${cfg.package}/bin/snix       $out/bin/snix
          ln -s ${cfg.package}/bin/snix-store $out/bin/snix-store
        '')
      ];

      # Ensure runtime and storage directories exist.
      systemd.tmpfiles.rules = [
        "d ${runtimeDir} 0755 root root -"
        "d ${castoreDir} 0755 root root -"
        "d ${storeDir}   0755 root root -"
      ];

      # 1. snix-store daemon: exposes the castore + path-info services over gRPC.
      #    Data lives under /tank/nixstore/snix-{castore,store}.
      systemd.services.snix-store-daemon = {
        description = "Snix store daemon (castore + path-info gRPC)";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        # Ensure /tank is mounted (ZFS) before we try to access storage.
        unitConfig.RequiresMountsFor = "/tank";

        environment = {
          BLOB_SERVICE_ADDR = "objectstore+file://${castoreDir}/blobs";
          DIRECTORY_SERVICE_ADDR = "redb:${castoreDir}/directories.redb";
          PATH_INFO_SERVICE_ADDR = "redb:${storeDir}/pathinfo.redb";
        };

        serviceConfig = {
          Type = "simple";
          ExecStart = "${cfg.package}/bin/snix-store daemon --listen-address ${storeGrpcSocket} --unix-listen-unlink --unix-listen-chmod everybody";
          Restart = "on-failure";
          RestartSec = 2;
          RuntimeDirectory = "snix";
          RuntimeDirectoryPreserve = true;
        };
      };

      # 2. nar-bridge: HTTP binary cache protocol frontend.
      #    Exposes the snix store as a standard Nix binary cache at port 9000.
      #    nginx proxies cache.jonringer.us to this.
      systemd.services.snix-nar-bridge = {
        description = "Snix nar-bridge (Nix HTTP binary cache)";
        # Disabled: not serving traffic yet, but store daemon + post-build-hook remain active.
        # wantedBy = [ "multi-user.target" ];
        after = [ "snix-store-daemon.service" ];
        requires = [ "snix-store-daemon.service" ];

        environment = {
          BLOB_SERVICE_ADDR = "grpc+unix:${storeGrpcSocket}";
          DIRECTORY_SERVICE_ADDR = "grpc+unix:${storeGrpcSocket}";
          PATH_INFO_SERVICE_ADDR = "grpc+unix:${storeGrpcSocket}";
        };

        serviceConfig = {
          Type = "simple";
          ExecStart = "${cfg.package}/bin/snix-nar-bridge --listen-address [::]:9000";
          Restart = "on-failure";
          RestartSec = 2;
          DynamicUser = true;
        };
      };
    })
  ];
}
