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
      dockerImage = pkgs.callPackage ./src/docker-image.nix {
        inherit name version;
      };
      # prodDockerImage = dockerImage.override {
      #   server = server.override {
      #     cliArgs = [
      #       "--use-production-cn"
      #       "--keep-alive"
      #     ];
      #   };
      # };
    in rec {
      packages = {
        help = pkgs.callPackage ./scripts/help.nix {
          inherit name version;
        };
        start = pkgs.callPackage ./scripts/start.nix {
          inherit name version dockerImage;
        };
        deploy = pkgs.callPackage ./scripts/deploy.nix {
          inherit name version dockerImage;
          # TODO: test and fix deploy
          # dockerImage = prodDockerImage;
        };
        default = packages.help;
      };
      apps = {
        help = utils.lib.mkApp { drv = packages.help; };
        start = utils.lib.mkApp { drv = packages.start; };
        deploy = utils.lib.mkApp { drv = packages.deploy; };
        default = apps.help;
      };
      devShells = {
        default = pkgs.mkShell {
          packages = [
            # ? pkgs.softether # vpnserver vpnbridge vpnclient vpncmd
            pkgs.psmisc # kill program at PORT using: fuser -k PORT/tcp
            pkgs.nix-prefetch-docker # get sha256 for dockerTools.pullImage using: nix-prefetch-docker --quiet --image-name _ --image-tag _ --image-digest sha256:_
            pkgs.podman # run docker containers without starting a daemon
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
