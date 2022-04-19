{ config, pkgs, ... }:

{
  services.prometheus = {
    enable = true;
    exporters.node = {
      enable = true;
    };
  };
}
