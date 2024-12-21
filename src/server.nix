# see https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/so/softether/package.nix

{
  pkgs,
  name,
  version
}: let
  dataDir = "/var/lib/softether";
  softether = pkgs.softether.override { inherit dataDir; };
in pkgs.writeShellApplication {
  name = "${name}-server-${version}";
  runtimeEnv = {
    DATA_DIR = dataDir;
    SOFTETHER_DIR = softether;
  };
  runtimeInputs = [
    softether
  ];
  text = builtins.readFile ./server.sh;
}
