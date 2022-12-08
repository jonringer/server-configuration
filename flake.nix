{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  #inputs.nixpkgs.url = "path:/home/jon/projects/nixpkgs";
  inputs.hydra.url = "github:NixOS/hydra";

  # https://github.com/NixOS/nix/pull/7283
  inputs.nixSource.url = "github:NixOS/nix/refs/tags/2.12.0";

  outputs = { self, nixpkgs, hydra, nixSource }: {

    nixosConfigurations.server = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
      ];
      specialArgs = {
        inherit (hydra.packages.${system}) hydra;
        inherit nixSource;
      };
    };

  };
}
