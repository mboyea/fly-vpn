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

interpret_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      native)
        : "${script:="$START_SERVER"}"
        shift
      ;;
      container)
        : "${script:="$START_SERVER_IN_CONTAINER"}"
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
  test_env SCRIPT_NAME START_SERVER START_SERVER_IN_CONTAINER
  # interpret CLI args
  interpret_args "$@"
  # if script was found in CLI args, run it
  if [[ -n "${script:-}" ]]; then
    "$script" "${unrecognized_args[@]}"
  # otherwise if no CLI args defined, run the default script
  elif [[ ! ${unrecognized_args[*]} ]]; then
    "$START_SERVER"
  # otherwise throw error that CLI args are invalid
  else
    echo_error "Invalid arguments:" "${unrecognized_args[@]}"
    exit 1
  fi
}

main "$@"
