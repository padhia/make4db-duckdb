{
  description = "make4db provier for DuckDB";

  inputs = {
    nixpkgs.url     = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    nix-utils.url = "github:padhia/nix-utils";
    nix-utils.inputs.nixpkgs.follows = "nixpkgs";

    make4db-api.url = "github:padhia/make4db-api";
    make4db-api.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
      nix-utils.follows = "nix-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nix-utils, make4db-api }:
  let
    inherit (nix-utils.lib) pyDevShell;
    inherit (nixpkgs.lib) composeManyExtensions;

    pkgOverlay = final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (py-final: py-prev: {
          make4db-duckdb = py-final.callPackage ./make4db-duckdb.nix {};
        })
      ];
    };

    overlays.default = composeManyExtensions [
      make4db-api.overlays.default
      pkgOverlay
    ];

    buildSystem = system:
    let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ self.overlays.default ];
      };

      devShells.default = pyDevShell {
        inherit pkgs;
        name = "make4db-duckdb";
        extra = [
          "duckdb"
          "make4db-api"
        ];
      };
    in { inherit devShells; };

  in {
    inherit overlays;
    inherit (flake-utils.lib.eachDefaultSystem buildSystem) devShells;
  };
}
