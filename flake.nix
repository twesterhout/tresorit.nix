{
  description = "Tresorit";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs:
    let
      tresorit-overlay = final: prev: {
        tresorit = final.callPackage ./tresorit.nix { };
        tresorit-wrapper = final.callPackage ./tresorit-wrapper.nix { };
      };

      pkgs-for = system: import inputs.nixpkgs {
        inherit system;
        overlays = [ tresorit-overlay ];
        config.allowUnfree = true;
      };
    in
    {
      packages = inputs.flake-utils.lib.eachDefaultSystemMap (system:
        let pkgs = (pkgs-for system);
        in {
          default = pkgs.tresorit-wrapper;
          tresorit = pkgs.tresorit;
          tresorit-wrapper = pkgs.tresorit-wrapper;
        });

      overlays.default = tresorit-overlay;
    };
}
