# print an error message to the console
echo_error() {
  echo "Error in $SCRIPT_NAME:" "$@" 1>&2;
}

# if the listed env variables aren't found, exit with an error message
test_env() {
  flags=$-
  # if u flag (exit when an undefined variable is used) was set, disable it
  if [[ $flags =~ u ]]; then
    set +u
  fi
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
  if [[ $flags =~ u ]]; then
    set -u
  fi
}

# interpret the arguments passed to this script
interpret_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      help)
        : "${script:="$HELP_SCRIPT"}"
        shift
      ;;
      init)
        : "${script:="$INIT_SCRIPT"}"
        shift
      ;;
      run)
        : "${script:="$RUN_SCRIPT"}"
        shift
      ;;
      start)
        : "${script:="$START_SCRIPT"}"
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

# entrypoint of this script
main() {
  test_env SCRIPT_NAME HELP_SCRIPT INIT_SCRIPT START_SCRIPT RUN_SCRIPT
  interpret_args "$@"
  # if script was found in the CLI args, run it
  if [[ -n "${script:-}" ]]; then
    exec "$script" "$@"
  # otherwise if no CLI args were given, run the default script
  elif [[ ! ${unrecognized_args[*]} ]]; then
    exec "$START_SCRIPT"
  # otherwise run the CLI args as a command
  else
    exec "$@"
  fi
}

main "$@"
