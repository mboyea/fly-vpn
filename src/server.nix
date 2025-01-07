# see https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/so/softether/package.nix

{
  pkgs,
  name,
  version,
  envVars ? {},
  cliArgs ? [],
}: let
  dataDir = "/var/lib/softether";
  # TODO: use mkDerivation to generate server.sh dependencies separately
  _softether = pkgs.softether.override { inherit dataDir; };
  softether = _softether.overrideAttrs (final: prev: {
    # postInstall = (prev.postInstall or "") + ''
    #   mkdir -p "$out${dataDir}/vpnserver"
    #   cat > "$out${dataDir}/vpnserver/init.txt" << EOF
    #   EOF
    # '';
  });
in pkgs.writeShellApplication {
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
