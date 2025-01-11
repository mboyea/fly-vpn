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

print_help() {
  echo "This is the $PROJECT_NAME command line interface."
  echo
  echo "Usage:"
  echo "  nix run [SCRIPT]  | Run the specified script"
  echo "  nix develop       | Start a dev shell with all project dependencies installed"
  echo
  echo "SCRIPTS:"
  echo "  .#help            | Print this helpful information"
  echo "  .#start           | Alias for .#start native"
  echo "  .#start native    | Start the server natively on your machine"
  echo "  .#start container | Start the server in a container on your machine"
  echo "  .#deploy          | Alias for .#deploy all"
  echo "  .#deploy server   | Deploy the server to Fly.io"
  echo "  .#deploy secrets  | Deploy the secrets to Fly.io"
  echo "  .#deploy all      | Deploy the server & secrets to Fly.io"
  echo
}

main() {
  test_env SCRIPT_NAME PROJECT_NAME
  print_help
}

main "$@"
