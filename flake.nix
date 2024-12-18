{
  description = "Fly VPN CLI.";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, ... }: let
    name = "fly-vpn";
    version = "0.0.0";
    utils = flake-utils;
  in utils.lib.eachDefaultSystem (
    system: let
      pkgs = import nixpkgs { inherit system; };
      server = pkgs.callPackage ./src/server.nix {
        inherit name version;
      };
    in rec {
      packages = {
        help = pkgs.callPackage ./scripts/help.nix {
          inherit name version;
        };
        start = pkgs.callPackage ./scripts/start.nix {
          inherit name version server;
        };
        default = packages.help;
      };
      apps = {
        help = utils.lib.mkApp { drv = packages.help; };
        start = utils.lib.mkApp { drv = packages.start; };
        default = apps.help;
      };
      devShells = {
        default = pkgs.mkShell {
          packages = [
            pkgs.psmisc # kill program at PORT using: fuser -k PORT/tcp
            pkgs.nix-prefetch-docker # get sha256 for dockerTools.pullImage using: nix-prefetch-docker --quiet --image-name _ --image-tag _ --image-digest sha256:_
            pkgs.podman
            pkgs.gzip
            pkgs.skopeo
            pkgs.flyctl
            pkgs.wireguard-tools
          ];
        };
      };
    }
  );
}
