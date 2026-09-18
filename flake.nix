{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  #inputs.nixpkgs.url = "path:/home/jon/projects/nixpkgs";
  inputs.hydra.url = "github:NixOS/hydra";
  #inputs.hydra.inputs.nixpkgs.follows = "nixpkgs";

  # Snix - Rust re-implementation of Nix. Used as a local-overlay backing
  # store and nar-bridge binary cache. Upstream has no flake.nix so we pull
  # the source in and build workspace members via crate2nix in ./snix-package.nix.
  inputs.snix = {
    url = "git+https://git.snix.dev/snix/snix.git";
    flake = false;
  };

  # For nix with content-addressed fixes
  inputs.repkgs = {
    url = "github:Mic92/repkgs";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Async post-build-hook: queues builds instead of blocking nix-daemon.
  inputs.queued-build-hook = {
    url = "github:nix-community/queued-build-hook";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: {

    nixosConfigurations.server = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        inputs.queued-build-hook.nixosModules.queued-build-hook
      ];
      specialArgs = {
        inherit inputs;
      };
    };

    packages.x86_64-linux.snix =
      inputs.nixpkgs.legacyPackages.x86_64-linux.callPackage ./snix-package.nix {
        # snix-package.nix imports the depot root (default.nix at the top of
        # the snix repo), which then exposes `.snix.crates.workspaceMembers`.
        snixSrc = inputs.snix;
      };
  };
}
