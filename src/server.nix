# see https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/so/softether/package.nix

{
  pkgs,
  name,
  version,
  softether,
  dataDir,
  envFile ? ".env",
  cliArgs ? [],
}: let
  _name = "${name}-server-${version}";
in pkgs.writeShellApplication {
  name = _name;
  runtimeEnv = {
    SCRIPT_NAME = _name;
    ADDITIONAL_CLI_ARGS = pkgs.lib.strings.concatStringsSep " " cliArgs;
    DATA_DIR = dataDir;
    SOFTETHER_INSTALL_DIR = softether;
    ENV_FILE = envFile;
  };
  runtimeInputs = [
    softether
  ];
  text = builtins.readFile ./server.sh;
}
