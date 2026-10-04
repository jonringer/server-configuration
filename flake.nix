{
  inputs = {
    corepkgs-v2.url = "github:ekala-project/corepkgs-v2";
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    #nixpkgs.url = "path:/home/jon/projects/nixpkgs";
    queued-build-hook = {
      url = "github:nix-community/queued-build-hook";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # dev-only deps
        devshell.follows = "";
        treefmt-nix.follows = "";
        pre-commit-hooks.follows = "";
      };
    };
    ekapkgs-cli = {
      url = "github:ekala-project/ekapkgs-cli?ref=jonringer/storage-signing";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: {
    nixosConfigurations.server = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        inputs.ekapkgs-cli.nixosModules.ekapkgs-serve
      ];
      specialArgs = {
        inherit inputs;
      };
    };
  };
}
