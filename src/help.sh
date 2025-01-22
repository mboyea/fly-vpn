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

# print information about this CLI
print_help() {
  echo "This is the $PROJECT_NAME help dialog."
  echo
  echo "This entrypoint provides some scripts."
  echo "SCRIPTS:"
  echo "  help  | Print this helpful information"
  echo "  init  | Init the server from env variables"
  echo "  run   | Run vpncmd commands"
  echo "  start | Start the server"
  echo "To call a script, set the container command (Cmd) to the script name."
  echo "If Cmd is not a recognized script, it will be executed as a bash command."
  echo "If Cmd is not provided, it will execute the start script by default."
  echo
}

# entrypoint of this script
main() {
  test_env SCRIPT_NAME PROJECT_NAME
  print_help
}

main "$@"
