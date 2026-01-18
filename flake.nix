{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  #inputs.nixpkgs.url = "path:/home/jon/projects/nixpkgs";
  inputs.hydra.url = "github:NixOS/hydra";
  #inputs.hydra.inputs.nixpkgs.follows = "nixpkgs";

  outputs = inputs: {

    nixosConfigurations.server = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
      ];
      specialArgs = {
        inherit inputs;
      };
    };

  };
}
