{
  description = "A Web Interface for Beancount";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        inherit (pkgs) buildNpmPackage fava;

        frontend = buildNpmPackage {
          inherit (fava) meta version;

          pname = "fava-frontend";
          src = ./frontend;
          sourceRoot = "frontend";

          nativeBuildInputs = with pkgs; [
            esbuild
            nodejs
          ];

          npmDepsHash = "";

          installPhase = ''
            mkdir -p $out
            cp -rf _build/* $out/
          '';
        };
      in
      {
        packages.default = pkgs.python3Packages.buildPythonPackage {
          inherit (pkgs.fava) meta version;

          pname = "fava";
          src = ./.;
          pyproject = true;

          nativeBuildInputs = [ pkgs.nodejs ];
          dependencies = with pkgs.python3Packages; [
            babel
            beancount
            build
            cheroot
            click
            flask
            flask-babel
            jaraco-functools
            jinja2
            markdown2
            ply
            setuptools
            setuptools-scm
            simplejson
            watchfiles
            werkzeug
          ];

          postFixup = ''
            mkdir -p src/fava/static
            cp -rf ${frontend}/* src/fava/static/
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs
          ];
        };
      }
    );
}
