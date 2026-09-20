{
  inputs = {
    corepkgs-v2.url = "github:ekala-project/corepkgs-v2";
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    #nixpkgs.url = "path:/home/jon/projects/nixpkgs";
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
