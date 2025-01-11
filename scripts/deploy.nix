{
  pkgs,
  name,
  version,
  dockerImage,
  flyConfig ? "fly.toml",
  envFile ? ".env",
  cliArgs ? [],
}: let
  _name = "${name}-deploy-${version}";
in pkgs.writeShellApplication {
  name = _name;
  runtimeEnv = {
    SCRIPT_NAME = _name;
    ADDITIONAL_CLI_ARGS = pkgs.lib.strings.concatStringsSep " " cliArgs;
    DOCKER_IMAGE_STREAM = dockerImage.stream;
    DOCKER_IMAGE_NAME = dockerImage.name;
    DOCKER_IMAGE_TAG = dockerImage.tag;
    FLY_CONFIG = flyConfig;
    ENV_FILE = envFile;
  };
  runtimeInputs = [
    pkgs.gzip
    pkgs.skopeo
    pkgs.flyctl
  ];
  text = builtins.readFile ./deploy.sh;
}
