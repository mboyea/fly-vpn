{
  pkgs,
  name,
  version,
  server,
  dockerImage,
  cliArgs ? [],
}: let
  _name = "${name}-start-${version}";
  dockerContainer = pkgs.callPackage ./mk-container.nix {
    inherit pkgs name version;
    image = dockerImage;
    podmanArgs = [
      "--publish"
      "5555:5555"
      "--publish"
      "992:992"
      "--publish"
      "443:443"
    ];
    imageArgs = [
      "--override-cn"
      "\"$host_ip\""
    ];
    preStart = ''
      # get ip of the container host machine to override the common name (cn) of the server
      host_ip=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -1)
    '';
    runAsRootUser = true;
  };
in pkgs.writeShellApplication {
  name = _name;
  runtimeEnv = {
    SCRIPT_NAME = _name;
    ADDITIONAL_CLI_ARGS = pkgs.lib.strings.concatStringsSep " " cliArgs;
    START_VPN_SERVER = pkgs.lib.getExe server;
    START_VPN_SERVER_IN_CONTAINER = pkgs.lib.getExe dockerContainer;
  };
  text = builtins.readFile ./start.sh;
}
