{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    #nixpkgs.url = "path:/home/jon/projects/nixpkgs";
    hydra.url = "github:NixOS/hydra";
    #inputs.hydra.inputs.nixpkgs.follows = "nixpkgs";

    # For nix with content-addressed fixes
    repkgs = {
      url = "github:Mic92/repkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

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
