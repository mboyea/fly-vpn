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

# if the required privileges aren't granted, exit with an error message
test_capabilities() {
  flags=$-
  # if e flag (exit when a program throws an error) was set, disable it
  if [[ $flags =~ e ]]; then set +e; fi
  # check that the iptables command works
  if ! iptables -L > /dev/null; then
    echo_error This script requires CAP_NET_ADMIN and CAP_NET_RAW
    exit 1
  fi
  # if e flag was set, re-enable it
  if [[ $flags =~ e ]]; then set -e; fi
}

# initialize the server if it isn't already
init_server() {
  # if the server config exists and has text, skip init
  if [ -s "/opt/vpn_server.config" ]; then
    echo "Server is already configured; Skipping init script..."
    return
  fi
  echo "Server is not yet configured; Running init script..."
  # call init script
  "$INIT_SCRIPT"
}

# start the server and print logs
start_server() {
  echo "Starting server; Printing server logs..."
  mkdir -p "$(realpath /opt)/server_log"
  touch "/opt/server_log/vpn_$(date +%Y%m%d).log"
  vpnserver execsvc & tail -n 0 -f "/opt/server_log/vpn_$(date +%Y%m%d).log"
}

# stop the server
stop_server() {
  echo "Stopping server..."
  vpnserver stop > /dev/null
  flags=$-
  # if e flag (exit when a program throws an error) was set, disable it
  if [[ $flags =~ e ]]; then set +e; fi
  # while pidof vpnserver works, sleep for 100ms
  while [[ $(pidof vpnserver) ]] > /dev/null; do
    sleep 0.1
  done
  # if e flag was set, re-enable it
  if [[ $flags =~ e ]]; then set -e; fi
  echo "Server stopped."
}

# entrypoint of this script
main() {
  test_env SCRIPT_NAME INIT_SCRIPT
  test_capabilities
  init_server
  trap stop_server EXIT
  start_server
}

main "$@"
