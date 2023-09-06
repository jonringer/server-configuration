{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  #inputs.nixpkgs.url = "path:/home/jon/projects/nixpkgs";
  inputs.hydra.url = "github:NixOS/hydra";
  inputs.dwarffs.url = "github:edolstra/dwarffs";

  outputs = { self, nixpkgs, hydra, dwarffs }: {

    nixosConfigurations.server = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        # https://github.com/edolstra/dwarffs
        # auto-fetch debug info files for gdb
        dwarffs.nixosModules.dwarffs
      ];
      specialArgs = {
        inherit (hydra.packages.${system}) hydra;
      };
    };

  };
}
