echo_error() {
  echo "Error in $SCRIPT_NAME:" "$@" 1>&2;
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

go_to_top_level_directory() {
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
}

load_env_file() {
  go_to_top_level_directory
  # if file isn't readable, return
  if [ ! -r "$ENV_FILE" ]; then
    return
  fi
  # load .env file
  set -a
  # shellcheck disable=SC1091 source=/dev/null
  source "$ENV_FILE"
  set +a
}

stage_env_file_to_fly_secrets() {
  go_to_top_level_directory
  # if file isn't readable, return
  if [ ! -r "$ENV_FILE" ]; then
    return
  fi
  # gather env secrets for flyctl
  flyctl_env_vars=()
  while IFS= read -r input_line || [[ -n "$input_line" ]]; do
    # ignore comments
    if [[ "$input_line" == '#'* ]]; then
      continue
    fi
    # remove quotes (until https://github.com/superfly/flyctl/issues/589 is resolved)
    flyctl_env_vars+=("$(echo "$input_line" | tr -d '"')")
  done < "$ENV_FILE"
  # set flyctl env secrets
  flyctl secrets set --stage "${flyctl_env_vars[@]}"
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
      server)
        # TODO: deploy only server
        shift
      ;;
      secrets)
        # TODO: deploy only secrets
        shift
      ;;
      all)
        # TODO: deploy server and secrets
        shift
      ;;
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
  test_env SCRIPT_NAME
  test_env ENV_FILE
  load_env_file
  test_env DOCKER_IMAGE_STREAM DOCKER_IMAGE_NAME DOCKER_IMAGE_TAG FLY_API_TOKEN FLY_APP_NAME FLY_CONFIG
  interpret_cli_args "$@"
  stage_env_file_to_fly_secrets
  deploy_docker_image_to_fly_registry
  load_docker_image_on_fly_server
}

main "$@"
