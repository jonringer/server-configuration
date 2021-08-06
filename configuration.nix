# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./prometheus-metrics.nix
    ];

  services.grafana.enable = true;
  services.grafana.addr = "10.0.0.21";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ (import ./overlays/factorio.nix) ];
  nix.autoOptimiseStore = true;
  nix.useSandbox = true;
  nix.nrBuildUsers = 450;
  nix.daemonIONiceLevel = 5;
  nix.daemonNiceLevel = 15;
  nix.buildCores = 32;
  nix.maxJobs = 64;
  nix.trustedUsers = [ "root" "@wheel" "jon" "nixpkgs-update" "tim" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.kernelModules = [ "zfs" ];
  boot.supportedFilesystems = [ "zfs" ];
  boot.extraModprobeConfig = ''
    options kvm-amd nested=1
    options kvm ignore_msrs=1
  '';

  nix.binaryCaches = [
  ];
  nix.binaryCachePublicKeys = [
  ];

  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  programs.bash.enableCompletion = true;
  networking.useDHCP = false;
  networking.interfaces.enp67s0.useDHCP = true;
  networking.interfaces.enp68s0.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  networking.hostId = "b5b5bea7";

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget vim git htop lm_sensors gitAndTools.hub
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.ports = [ 22 2222 3000 9100 ];
  services.openssh.extraConfig = ''
    StreamLocalBindUnlink yes
  '';
  services.openssh.authorizedKeysFiles = [
    "/etc/ssh/extra_authorized_keys"
  ];

  services.ipfs = {
    enable = true;
    dataDir = "/tank/ipfs";
    autoMount = true;
  };

  services.plex = {
    enable = true;
    group = "users";
    openFirewall = true;
  };

  services.factorio = {
    enable = true;
    package = pkgs.factorio-headless-experimental;
    autosave-interval = 10;
    openFirewall = true;
    description = "MFG's adventure in Space";
    admins = [ "CheesyMcPuffs" "MostFunGuy" "ArroneXB" "PatHeist" "Rubber.Ducky" ];
    game-name = "OTGG in Space, Dedicated";
    game-password = "mfg";
    public = true;
    lan = true;
    token = "331c2d6bee32339c8bab60cab4a524";
    username = "CheesyMcPuffs";
    saveName = "MFGinSpace";
    nonBlockingSaving = true;
  };

   services.transmission = {
     enable = true;
     group = "users";
     settings = {
       download-dir = "/tank/torrents";
       incomplete-dir = "/tank/torrents/.incomplete";
       incomplete-dir-enabled = true;
       message-level = 1;
       peer-port = 51413;
       peer-port-random-high = 65535;
       peer-port-random-low = 49152;
       peer-port-random-on-start = false;
       rpc-bind-address = "127.0.0.1";
       rpc-port = 9091;
       script-torrent-done-enabled = false;
       script-torrent-done-filename = "";
       umask = 2;
       utp-enabled = true;
       watch-dir = "/var/lib/transmission/watchdir";
       watch-dir-enabled = false;
     };
   };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  services.gnome.at-spi2-core.enable = true;
  virtualisation.libvirtd.enable = true;

  networking.firewall.allowedTCPPorts = [ 9091 9100 5001 2222 34159 ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jon = {
    isNormalUser = true;
    extraGroups = [ "wheel" "plex" "libvirtd" ];
  };

  users.users.tim = {
    isNormalUser = true;
    extraGroups = [ "libvirtd" ];
  };
  
  users.users.tomberek = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDSF4CzkvONzaze5m0huhLmED9fxQTtuyv7rszWI0ju/+U4Gq4+Sd800vFrADfnbiLS4hgK4pDw5D8dXxi74mPeXXZV4oomafCnlvW7tL7RidEXvkP2sr1ObgkuQ9K67hSqKjT21mCWdEN6WGHh9EtK5r3nXIzUWhATqDz/Al7sveDZ/gdapo+f3xnmpOu1mq+y5iOcRV7b98z/VaiWAvuG83toIBsK4Su/GWWfMNied9R2K2Z10NM3ART0Sk+4yqH4usJOieTQsLAq8Ykb3PAYDMVx41yy9QNcFnCyX/HJHFO/Q98BLQ2zPxVbBMwp99NrKLqrwkrVtrWbAttanm9 cardno:000607658414"
    ];
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?

}

