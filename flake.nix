{
  description = "make4db tool for duckdb";

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

    make4db-src.url = "github:padhia/make4db";
    make4db-src.flake = false;

    yappt.url = "github:padhia/yappt";
    yappt.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
      nix-utils.follows = "nix-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nix-utils, make4db-api, make4db-src, yappt }:
  let
    inherit (nix-utils.lib) pyDevShell mkApps;
    inherit (nixpkgs.lib) composeManyExtensions;

    pkgOverlay = final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (py-final: py-prev: rec {
          make4db-provider-duckdb = py-final.callPackage ./make4db-duckdb.nix {};
          make4db-duckdb = py-final.callPackage "${make4db-src}/make4db.nix" { make4db-provider = make4db-provider-duckdb; };
        })
      ];
    } // { inherit (final.python3Packages) make4db-duckdb; };

    overlays.default = composeManyExtensions [
      yappt.overlays.default
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
          "make4db-api"
          "duckdb"
        ];
      };

      packages.default = pkgs.make4db-duckdb;

      apps = mkApps {
        pkg = packages.default;
        cmds = [ "m4db" "m4db-cache" "m4db-gc" "m4db-refs" ];
      };

    in { inherit devShells packages apps; };

  in {
    inherit overlays;
    inherit (flake-utils.lib.eachDefaultSystem buildSystem) devShells packages apps;
  };
}
