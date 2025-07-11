{
  inputs = {
    nixpkgs.url     = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    make4db-api.url = "github:padhia/make4db-api";

    make4db-api.inputs.nixpkgs.follows = "nixpkgs";
    make4db-api.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, make4db-api }:
  let
    inherit (nixpkgs.lib) composeManyExtensions;

    overlays.default =
    let
      pkgOverlay = final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (py-final: py-prev: {
            make4db-duckdb = py-final.callPackage ./make4db-duckdb.nix {};
          })
        ];
      };
    in composeManyExtensions [
      make4db-api.overlays.default
      pkgOverlay
    ];

    eachSystem = system:
    let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ self.overlays.default ];
      };

      pyPkgs = pkgs.python312Packages;

    in {
      devShells.default = pkgs.mkShell {
        name = "m4db-duck";
        venvDir = "./.venv";
        buildInputs = [
          pkgs.ruff
          pkgs.uv
          pyPkgs.python
          pyPkgs.venvShellHook
          pyPkgs.pytest
          pyPkgs.duckdb
          pyPkgs.make4db-api
        ];
      };
    };

  in {
    inherit overlays;
    inherit (flake-utils.lib.eachDefaultSystem eachSystem) devShells;
  };
}
