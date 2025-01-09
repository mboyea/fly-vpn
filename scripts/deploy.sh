echo_error() {
  echo "Error in $SCRIPT_NAME:" "$@" 1>&2;
}

load_env() {
  # go to top-level directory
  base_dir="$(git rev-parse --show-toplevel)"
  cd "$base_dir"
  # load .env file
  if [ -r .env ]; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
  fi
}

test_env() {
  # disable exit on undefined variable use
  set +u
  # for each env variable
  while [[ $# -gt 0 ]]; do
    # check that env variable is defined
    if [ -z "${!1}" ]; then
      echo_error The required environment variable "$1" is not defined
      exit 1
    fi
    shift
  done
  # enable exit on undefined variable use
  set -u
}

deploy_docker_image_to_fly_registry() {
  "$DOCKER_IMAGE_STREAM" | gzip --fast | skopeo --insecure-policy copy --dest-creds="x:$FLY_API_TOKEN" "docker-archive:/dev/stdin" "docker://registry.fly.io/$FLY_APP_NAME:$DOCKER_IMAGE_TAG"
  # ? podman can perform the required commands to imitate skopeo copy; one may be faster than the other, I don't yet know; my guess is skopeo + gzip does this faster than podman, so I'm using skopeo
  # podman login -u x -p "$FLY_API_TOKEN" -v registry.fly.io
  # "$DOCKER_IMAGE_STREAM" | podman load
  # podman push --format v2s2 "localhost/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG" "docker://registry.fly.io/$FLY_APP_NAME:$DOCKER_IMAGE_TAG"
}

load_docker_image_on_fly_server() {
  flyctl deploy -c "$FLY_CONFIG" -i "registry.fly.io/$FLY_APP_NAME:$DOCKER_IMAGE_TAG"
}

interpret_cli_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      *)
        unrecognized_args+=("$1")
        shift
      ;;
    esac
  done
  set -- "${unrecognized_args[@]}"
}

main() {
  set -- "$@" "$ADDITIONAL_CLI_ARGS" # set additional CLI args passed by Nix
  load_env
  test_env SCRIPT_NAME DOCKER_IMAGE_STREAM DOCKER_IMAGE_NAME DOCKER_IMAGE_TAG FLY_API_TOKEN FLY_APP_NAME FLY_CONFIG 
  interpret_cli_args "$@"
  deploy_docker_image_to_fly_registry
  load_docker_image_on_fly_server
}

main "$@"
