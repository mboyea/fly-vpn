{
  pkgs,
  name,
  version,
  dockerImage,
  cliArgs ? [],
  flyConfig ? "fly.toml"
}: let
  _name = "${name}-deploy-${version}";
in pkgs.writeShellApplication {
  name = _name;
  runtimeInputs = [
    pkgs.gzip
    pkgs.skopeo
    pkgs.flyctl
  ];
  runtimeEnv = {
    SCRIPT_NAME = _name;
    ADDITIONAL_CLI_ARGS = pkgs.lib.strings.concatStringsSep " " cliArgs;
    DOCKER_IMAGE_STREAM = dockerImage.stream;
    DOCKER_IMAGE_NAME = dockerImage.name;
    DOCKER_IMAGE_TAG = dockerImage.tag;
    FLY_CONFIG = flyConfig;
  };
  text = builtins.readFile ./deploy.sh;
}
