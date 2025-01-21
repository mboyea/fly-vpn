{
  pkgs,
  name,
  version,
  server,
  dockerImage,
  envFile ? ".env",
  cliArgs ? [],
}: let
  _name = "${name}-start-${version}";
  # podman pull docker.io/siomiz/softethervpn 
  # podman container run --tty --interactive --privileged siomiz/softethervpn
  dockerContainer = pkgs.callPackage ../utils/mk-container.nix {
    inherit name version;
    image = dockerImage;
    runAsRootUser = true;
    podmanArgs = [
      "--privileged"
      # "--cap-add" "NET_ADMIN" # ! this doesn't work
      "--publish" "443:443/tcp"
      "--publish" "992:992/tcp"
      "--publish" "5555:5555/tcp"
      "--publish" "500:500/udp"
      "--publish" "1194:1194/udp"
      "--publish" "1701:1701/udp"
      "--publish" "4500:4500/udp"
      "--env-file" "/tmp/${_name}/${envFile}"
    ];
    imageArgs = [
      # "--override-cn" "\"$host_ip\"" # ! enable this
    ];
    preStart = ''
      # sanitize .env for podman --env-file due to quotes (") not being handled properly https://github.com/containers/podman-compose/issues/370
      mkdir -p "/tmp/${_name}"
      sed 's/"\(.*\)"/\1/' ${envFile} > "/tmp/${_name}/${envFile}"

      # get ip of the container host machine to override the common name (cn) of the server
      host_ip=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -1)
    '';
    postStop = ''
      rm -rf "/tmp/${_name}/${envFile}"
      echo "$host_ip" # ! remove this
    '';
  };
in pkgs.writeShellApplication {
  name = _name;
  runtimeEnv = {
    SCRIPT_NAME = _name;
    ADDITIONAL_CLI_ARGS = pkgs.lib.strings.concatStringsSep " " cliArgs;
    START_SERVER = pkgs.lib.getExe server;
    START_SERVER_IN_CONTAINER = pkgs.lib.getExe dockerContainer;
  };
  text = builtins.readFile ./start.sh;
}
