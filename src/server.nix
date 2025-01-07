# see https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/so/softether/package.nix

{
  pkgs,
  name,
  version,
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
    SOFTETHER_PASS = "password"; # TODO: pull from .env
    # DNS_URL = ; # TODO: pull from .env
    USER_PASS_PAIRS = "user1:pass user2:pass user3:pass"; # TODO: pull from .env
  };
  runtimeInputs = [
    softether
  ];
  text = builtins.readFile ./server.sh;
}
