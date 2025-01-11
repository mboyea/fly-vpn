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
  dockerContainer = pkgs.callPackage ../utils/mk-container.nix {
    inherit name version;
    image = dockerImage;
    podmanArgs = [
      "--publish"
      "5555:5555"
      "--publish"
      "992:992"
      "--publish"
      "443:443"
      # TODO --env-file .env (but grep delete '"')
      "--env"
      "SOFTETHER_PASS"
      "--env"
      "USER_PASS_PAIRS"
    ];
    imageArgs = [
      "--override-cn"
      "\"$host_ip\""
    ];
    preStart = ''
      # get ip of the container host machine to override the common name (cn) of the server
      host_ip=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -1)

      # TODO: delete all this by implementing above TODO
      # load the env file if it exists
      load_env_file() {
        # if git is not installed, return
        if ! [ -x "$(command -v git)" ]; then
          return
        fi
        # if current directory is not a git directory, return
        if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
          return
        fi
        # go to top-level of git directory
        base_dir="$(git rev-parse --show-toplevel)"
        cd "$base_dir"
        # load .env file if it exists
        if [ -r "${envFile}" ]; then
          set -a
          # shellcheck disable=SC1091 source=/dev/null
          source "${envFile}"
          set +a
        fi
      }

      load_env_file
    '';
    runAsRootUser = true;
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
