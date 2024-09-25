{
  description = "A Web Interface for Beancount";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      poetry2nix,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        inherit (pkgs) buildNpmPackage fava;
        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication;
        frontend = buildNpmPackage {
          inherit (fava) meta version;

          pname = "fava-frontend";
          src = ./frontend;
          sourceRoot = "frontend";

          nativeBuildInputs = with pkgs; [
            esbuild
            nodejs
          ];

          npmDepsHash = "sha256-cLULNIaBIUJ5QbFn9HXaxpafi3/YKRC6SN7FNIe2AZs=";

          installPhase = ''
            mkdir -p $out
            cp -rf _build/* $out/
          '';
        };
      in
      {
        packages.default = mkPoetryApplication {
          projectDir = ./.;
          preferWheels = true;

          postInstall = ''
            mkdir -p $out/lib/python3.*/site-packages/fava/static
            cp -rf ${frontend}/* $out/lib/python3.*/site-packages/fava/static/
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs
            poetry
          ];
        };
      }
    );
}
