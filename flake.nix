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
      url = "github:ekala-project/ekapkgs-cli";
      flake = false;
    };
    eka-ci = {
      url = "github:ekala-project/eka-ci";
      flake = false;
    };
  };

  outputs = inputs: let
      ekapkgs-cli = inputs.ekapkgs-cli + "/nix/module.nix";
      eka-ci = inputs.eka-ci + "/nix/module.nix";
  in {
    nixosConfigurations.server = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        ekapkgs-cli
        eka-ci
        ./eka-ci.nix
      ];
      specialArgs = {
        inherit inputs;
      };
    };
  };
}
