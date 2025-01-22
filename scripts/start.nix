{
  pkgs,
  name,
  version,
  dockerImage,
  envFile ? ".env",
  cliArgs ? [],
}: let
  _name = "${name}-start-${version}";
  dockerContainer = pkgs.callPackage ../utils/mk-container.nix {
    inherit name version;
    image = dockerImage;
    runAsRootUser = true;
    podmanArgs = [
      "--privileged"
      # TODO figure out specific privileges required
      # "--cap-add" "NET_ADMIN" # ! this doesn't work
      "--publish" "443:443/tcp"
      "--publish" "992:992/tcp"
      "--publish" "5555:5555/tcp"
      "--publish" "500:500/udp"
      "--publish" "1194:1194/udp"
      "--publish" "1701:1701/udp"
      "--publish" "4500:4500/udp"
      # sanitize .env for podman --env-file due to quotes (") not being handled properly
      # https://github.com/containers/podman-compose/issues/370
      "--env-file" ''<(sed 's/"\(.*\)"/\1/' "${envFile}")''
      # get ip of the container host machine to override the common name (cn) of the server
      "--env" ''"CN_OVERRIDE=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -1)"''
    ];
    defaultImageArgs = [
      "start"
    ];
  };
in pkgs.writeShellApplication {
  name = _name;
  runtimeEnv = {
    SCRIPT_NAME = _name;
    ADDITIONAL_CLI_ARGS = pkgs.lib.strings.concatStringsSep " " cliArgs;
    START_SERVER_IN_CONTAINER = pkgs.lib.getExe dockerContainer;
  };
  text = builtins.readFile ./start.sh;
}
