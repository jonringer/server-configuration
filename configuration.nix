# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, hydra, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./prometheus-metrics.nix
      ./web.nix
    ];

  services.grafana.enable = true;
  services.grafana.addr = "0.0.0.0";
  services.grafana.port = 3050;
  services.grafana.auth.anonymous.enable = true;

  systemd.services.nix-daemon.serviceConfig.LimitNOFILE = lib.mkForce 131072;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ ];
  nix.autoOptimiseStore = true;
  nix.useSandbox = true;
  nix.nrBuildUsers = 450;
  nix.buildCores = 32;
  nix.maxJobs = 40;
  nix.trustedUsers = [ "root" "@wheel" "jon" "nixpkgs-update" "tim" "jtojnar" ];
  nix.package = pkgs.nixVersions.unstable;
  # Flake support
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  nix.gc.automatic = true;
  nix.gc.options = "--max-freed 100G";
  # every 3rd day
  nix.gc.dates = "*-*-1,4,7,10,13,16,19,22,25,28,31 00:00:00";

  services.nix-serve.enable = true;
  services.nix-serve.secretKeyFile = "/var/cache-priv-key.pem";

  # Use the systemd-boot EFI boot loader.
  boot.kernel.sysctl."net.core.rmem_max" = lib.mkForce 4150000;
  boot.kernel.sysctl."vm.swappiness" = 0;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmpOnTmpfs = true;
  boot.tmpOnTmpfsSize = "40%";

  boot.initrd.kernelModules = [ "zfs" ];
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportAll = true;
  services.zfs.trim.enable = true;
  hardware.cpu.amd.updateMicrocode = true;
  boot.extraModprobeConfig = ''
    options kvm-amd nested=1
    options kvm ignore_msrs=1
  '';
  services.sanoid = {
    enable = true;
    datasets."nixstore/nix" = {
      daily = 3;
      autoprune = true;
      autosnapshot = true;
    };
  };

  nix.binaryCaches = [
  ];
  nix.binaryCachePublicKeys = [
  ];

  services.postgresql.package = pkgs.postgresql_14;
  services.hydra = {
    enable = true;
    package = hydra;

    hydraURL = "https://hydra.jonringer.us";
    notificationSender = "hydra@jonringer.us";
    buildMachinesFiles = [ ];
    useSubstitutes = true;

    port = 3100;
  };
  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  programs.bash.enableCompletion = true;
  programs.mosh.enable = true;
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    interactiveShellInit = ''
      source ${pkgs.grml-zsh-config}/etc/zsh/zshrc
    '';
    promptInit = ""; # otherwise it'll override the grml prompt
  };
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
    wget vim git htop lm_sensors gitAndTools.hub tmux
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
    enable = false;
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

  security.pam.loginLimits = [{
    domain = "*";
    type = "soft";
    item = "nofile";
    value = "4096";
  }];

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  services.gnome.at-spi2-core.enable = true;
  virtualisation.libvirtd.enable = true;

  networking.firewall.allowedTCPPorts = [
    config.services.hydra.port
    config.services.nix-serve.port
    config.services.grafana.port
    80 443 9091 9100 5001 2222 34159
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jon = {
    isNormalUser = true;
    extraGroups = [ "wheel" "plex" "libvirtd" ];
  };

  users.users.tim = {
    isNormalUser = true;
    extraGroups = [ "libvirtd" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIf7jDfqGKNZVwrJ3Yl+4aJe8sZpCmhlOB5PJC9L1Kto tim.deherrera@iohk.io"
    ];
  };

  # aka. lovesegfault
  users.users.bemeurer = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFAvxz7tBCov9310ucqrVeAS0aSWCVh5sSsLjH/62lIldFPd7JVK5y+f5VETycoRy9aQSzzlb4wsXtCX0WMtRx8tWbeV4MVXHSDROQEI1QpWM5BPgrLdNB5zR+czjSb0It+3XrzzOiu1RaIY/48EEhxxshghLEVQqwHplObQI9yzdxfVPD9ZOqbxQRi6hYm9uEU3DcAONhLDAIlaDltmZVr7Vfg3P+eucO+QJ7/aLuochWLxLX/NjBsihYLrZIY+y1JAP2jm+dkGVTimozr/zwopO4y4+FlLK71ZbE1xlLX/UZHdfN00rmmZwzeTN+S7+H3cQSCQO6p6qmk9fT94sr9S7pKa8/fSr/1q7wbvKcoOW0hYal4XHnuON58+kA7thgZgFEji6o9KqWsss1wqx/XLYu2ThU6OpplPzhL+AwaH1uQpmoQ5ge29Emadv42R1jw0js2nljA4sJFybFmV0LJwORvqjaYuEj2peS40BT3eI+51plD85p//gmTeT3W7zqR8KB5bWK1xzWReSOI0Vg6PGiBPSA38dH5V7OZXDjZRnlE1WTD3E7MVKGhQDwQHoQdAvNSG7LyBfK7eprCTQAR/LkTaIQrCxLsIkzoSor5ZkG6P+QWN+HaN9YFJT6p7TtHbzZqpRkKAcVkNwXcGOyIw4ofybmUUEQ8O5Y8CC9Fw== cardno:000610250089"
    ];
  };

  users.users.boredom101 = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCjeemhlJimE+5/THTqeKyXuW2+2iDSZDdG0P2gz0x8SqQGJ5VeOYcxbOBzDdjXxgkScSVuCKbwSitpMsgLLlYhm3CfSP8rN0lhxz0t7Q7H6OWHzll07qLVvlh4BbBOwod8+NKHcPe+4Paur754IOlwCOb4kDRaUXBmyl84lgTik5g7m7XI7JJIQbZovguBZIVMjMNAPOonqL86OEk3WiuGOKrGFstLjl9P6LuA01Mz2E446PiajEMhzS5xPxs2s5Z/lT0+gLDdISQN69PaXy0kSZkXpjzoUADfgz4aZ/MgYTn6qR4ntlVHKxUpo8EbuTleFwsjMRHRA8bmCFReX4MMcj8/b0Vlzu7f9k1wADJAAT9GW+EVz7xgC4k9mMr0eWoYLYs0txuHwnG9DbA487p5R+P9LfUrXIYdqnk4YzvjbFIBJQIi3SQFdGlY1Z1989sQBBuuRkomZmnvKk1JPnrNtYQaXN4BzfJGydzpW8wEH/lBvoFckUviBodzGlCWnHk= yisroel@DESKTOP-MKI0HG0"
    ];
  };

  users.users.tomberek = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDSF4CzkvONzaze5m0huhLmED9fxQTtuyv7rszWI0ju/+U4Gq4+Sd800vFrADfnbiLS4hgK4pDw5D8dXxi74mPeXXZV4oomafCnlvW7tL7RidEXvkP2sr1ObgkuQ9K67hSqKjT21mCWdEN6WGHh9EtK5r3nXIzUWhATqDz/Al7sveDZ/gdapo+f3xnmpOu1mq+y5iOcRV7b98z/VaiWAvuG83toIBsK4Su/GWWfMNied9R2K2Z10NM3ART0Sk+4yqH4usJOieTQsLAq8Ykb3PAYDMVx41yy9QNcFnCyX/HJHFO/Q98BLQ2zPxVbBMwp99NrKLqrwkrVtrWbAttanm9 cardno:000607658414"
    ];
  };

  users.users.bill = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEG2lfvWM5a7Xy255kRZN1c2Z5QToUm8ecF+/lP7FpS0 bill@ewanick.com"
    ];
  };

  users.users.jtojnar = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEH4OFCc6a84dXHFHjNQ2HohLTFcYkxe+Lz/t3teWCrQ jtojnar@brian"
    ];
  };

  users.users.jurraca = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDGmwV0S9JoNaO3mMpSrjkv2gD4Vd0hw2ljLKaRzMQpv jurraca@nix"
    ];
  };

  users.users.cleeyv = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO4p4CqilI3n1GOyGcDgUh1UpwxeHSTIiV4oeHYjF431 cleeyv"
    ];
  };

  users.users.tshaynik = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO3wOOYiW+G1u5zHpvzq0N+nhj5l9o8lMht4kYias28n tshaynik"
    ];
  };

  users.users.artturin = {
    shell = pkgs.zsh;
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDtXhvhk+LLfrO2K11ftf2qRaczYvEJLLr7tNsENuErQ ar-keyfor-rs"
    ];
  };

  users.users.happysalada = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGyQSeQ0CV/qhZPre37+Nd0E9eW+soGs+up6a/bwggoP raphael@RAPHAELs-MacBook-Pro.local"
    ];
  };

  users.users.ysander = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL6VLyCv4qmk2coyzhjm4qhd5LpsTmbNGh1HbJOWzYvj openpgp:0xF401BBD4"
    ];
  };

  users.users.synthetica = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFZaNsfqer68KD68f2udjv6BGg66aaIdTFMB50iaYK21 synthetica@AquaRing"
    ];
  };

  users.users.dermetfan = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBiYIJBUMPZqmFUcqaVp5h+6lsmvHIAZhCAjJ8a3El/2 dermetfan@laptop"
    ];
  };

  users.users.milahu = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBuzJ8xfKAkt6m0ByZK26LZQaQQGsaX68D5/9UeiVGb9 user@laptop1"
    ];
  };

  # DavHau
  users.users.davhau = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDuhpzDHBPvn8nv8RH1MRomDOaXyP4GziQm7r3MZ1Syk"
    ];
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?

}
