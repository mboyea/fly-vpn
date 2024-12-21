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
