# see https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/so/softether/package.nix

{
  pkgs,
  name,
  version,
  softether ? pkgs.softether,
  dataDir,
  envVars ? {},
  cliArgs ? [],
}: pkgs.writeShellApplication {
  name = "${name}-server-${version}";
  runtimeEnv = {
    DATA_DIR = dataDir;
    SOFTETHER_INSTALL_DIR = softether;
    ADDITIONAL_CLI_ARGS = pkgs.lib.strings.concatStringsSep " " cliArgs;
  } // envVars;
  runtimeInputs = [
    softether
  ];
  text = builtins.readFile ./server.sh;
}
