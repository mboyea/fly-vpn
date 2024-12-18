{
  pkgs,
  name,
  version,
  server,
  cliArgs ? []
}: let
  _name = "${name}-start-${version}";
in pkgs.writeShellApplication {
  name = _name;
  runtimeEnv = {
    SCRIPT_NAME = _name;
    ADDITIONAL_CLI_ARGS = pkgs.lib.strings.concatStringsSep " " cliArgs;
    START_VPN_SERVER = pkgs.lib.getExe server;
  };
  text = builtins.readFile ./start.sh;
}
