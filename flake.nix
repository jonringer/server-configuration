{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  #inputs.nixpkgs.url = "path:/home/jon/projects/nixpkgs";
  inputs.hydra.url = "github:NixOS/hydra";

  outputs = { self, nixpkgs, hydra }: {

    nixosConfigurations.server = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
      ];
      specialArgs = {
        inherit (hydra.packages.${system}) hydra;
      };
    };

  };
}
