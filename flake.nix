{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  #inputs.nixpkgs.url = "path:/home/jon/projects/nixpkgs";
  inputs.hydra.url = "github:NixOS/hydra";

  # https://github.com/NixOS/nix/pull/7283
  inputs.nixSource.url = "github:NixOS/nix/62960f32915909a5104f2ca3a32b25fb3cfd34c7";

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
