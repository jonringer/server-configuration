{ config, pkgs, ... }:

{
  services.prometheus = {
    enable = false;
    exporters.node = {
      enable = false;
    };
  };
}
