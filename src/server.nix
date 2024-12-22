# see https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/so/softether/package.nix

{
  pkgs ? import <nixpkgs> {},
  name ? "test",
  version ? "0.0.0",
}: let
  dataDir = "/var/lib/softether";
  # TODO: use mkDerivation to generate server.sh dependencies separately
  # ? to avoid softether rebuilds when ./server-init.txt is modified
  _softether = pkgs.softether.override { inherit dataDir; };
  softether = _softether.overrideAttrs (final: prev: {
    postInstall = (prev.postInstall or "") + ''
      mkdir -p "$out${dataDir}/vpnserver"
      cat > "$out${dataDir}/vpnserver/init.txt" << EOF
      ${builtins.readFile ./server-init.txt}
      EOF
    '';
  });
in pkgs.writeShellApplication {
  name = "${name}-server-${version}";
  runtimeEnv = {
    DATA_DIR = "/var/lib/softether";
    SOFTETHER_DIR = softether;
    SOFTETHER_PWD = "password";
  };
  runtimeInputs = [
    softether
  ];
  text = builtins.readFile ./server.sh;
}
