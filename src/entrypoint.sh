# print an error message to the console
echo_error() {
  echo "Error in $SCRIPT_NAME:" "$@" 1>&2;
}

# if the listed env variables aren't found, exit with an error message
test_env() {
  flags=$-
  # if u flag (exit when an undefined variable is used) was set, disable it
  if [[ $flags =~ u ]]; then set +u; fi
  # for each env variable
  while [[ $# -gt 0 ]]; do
    # check that env variable is defined
    if [ -z "${!1}" ]; then
      echo_error The required environment variable "$1" is not defined
      exit 1
    fi
    shift
  done
  # if u flag was set, re-enable it
  if [[ $flags =~ u ]]; then set -u; fi
}

# entrypoint of this script
main() {
  test_env SCRIPT_NAME HELP_SCRIPT INIT_SCRIPT START_SCRIPT RUN_SCRIPT
  # if no Cmd was given, run the default script
  if [[ $# -eq 0 ]]; then
    exec "$START_SCRIPT"
  fi
  # otherwise run the script specified by the first Cmd argument
  case $1 in
    help)
      shift
      exec "$HELP_SCRIPT" "$@"
    ;;
    init)
      shift
      exec "$INIT_SCRIPT" "$@"
    ;;
    run)
      shift
      exec "$RUN_SCRIPT" "$@"
    ;;
    start)
      shift
      exec "$START_SCRIPT" "$@"
    ;;
    *)
      exec "$@"
    ;;
  esac
}

main "$@"
