# see https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/so/softether/package.nix

{
  pkgs,
  name,
  version,
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
    ENV_FILE = envFile;
  };
  text = builtins.readFile ./server.sh;
}
