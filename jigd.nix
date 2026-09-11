# jigd NixOS module — compilation cache daemon.
#
# Usage:
#   services.jigd.enable = true;
#
# Then use `nix build` via the wrapper or pass
#   --option extra-sandbox-paths /run/jigd/jigd.sock
# so that builders can reach the cache socket.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.jigd;

  defaultJigPackage = pkgs.callPackage ./jig-package.nix {};
  defaultJigdPackage = pkgs.callPackage ./jigd-package.nix {};
in {
  options.services.jigd = {
    enable = lib.mkEnableOption "jigd compilation cache daemon";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultJigdPackage;
      description = "The jigd package to use.";
    };

    jigPackage = lib.mkOption {
      type = lib.types.package;
      default = defaultJigPackage;
      description = "The jig compiler wrapper package to install.";
    };

    socketPath = lib.mkOption {
      type = lib.types.str;
      default = "/run/jigd/jigd.sock";
      description = "Path to the jigd Unix socket.";
    };

    cacheSize = lib.mkOption {
      type = lib.types.int;
      default = 50;
      description = "Cache budget in GiB. Least-recently-read packs are evicted when exceeded.";
    };

    slots = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Maximum concurrent compiler processes. Defaults to CPU count.";
    };

    openSandbox = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Add the jigd socket to nix's extra-sandbox-paths so that builds
        inside the sandbox can reach the compilation cache automatically.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Install jig compiler wrapper on $PATH and point it at the socket
    environment.systemPackages = [ cfg.jigPackage ];
    environment.variables.JIG_SOCK = cfg.socketPath;

    # jigd systemd service
    systemd.services.jigd = {
      description = "jigd compilation cache daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];

      environment = {
        JIGD_SIZE = toString cfg.cacheSize;
        XDG_CACHE_HOME = "/var/cache/jigd";
      } // lib.optionalAttrs (cfg.slots != null) {
        JIGD_SLOTS = toString cfg.slots;
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/jigd ${cfg.socketPath}";
        Restart = "on-failure";
        RestartSec = 2;

        # Directories
        RuntimeDirectory = "jigd";
        RuntimeDirectoryMode = "0755";
        CacheDirectory = "jigd";
        CacheDirectoryMode = "0700";

        # Sandboxing
        DynamicUser = true;
        ProtectHome = true;
        PrivateTmp = true;
      };
    };

    # Map socket into Nix sandbox so builds can use the cache
    nix.settings.extra-sandbox-paths = lib.mkIf cfg.openSandbox [
      cfg.socketPath
    ];
  };
}
