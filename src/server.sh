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

# load server files from the backup directory
load_backup_files() {
  echo "Loading server backup files..."
  backup_dir="/var/opt/backup"
  server_dir="$(realpath /opt)"
  [[ ! -d "$backup_dir" ]] && return
  cp -rf "$backup_dir/"* "$server_dir"
  echo "Done loading server backup files..."
}

# save server files to the backup directory
save_backup_files() {
  echo "Backing up server files..."
  backup_dir="/var/opt/backup"
  server_dir="$(realpath /opt)"
  [[ ! -d "$backup_dir" ]] && mkdir -p "$backup_dir"
  cp -rf "$server_dir/"* "$backup_dir"
  echo "Done backing up server files."
}

# initialize the server if it isn't already
init_server() {
  config_file="$(realpath /opt)/vpn_server.config"
  # if the server config exists and has text, skip init
  if [ -s "$config_file" ]; then
    echo "Server is already configured; Skipping init script..."
    return
  fi
  echo "Server is not yet configured; Running init script..."
  # call init script
  "$INIT_SCRIPT"
}

# start the server and print logs
start_server() {
  log_file="$(realpath /opt)/server_log/vpn_$(date +%Y%m%d).log"
  echo "Starting server; Printing server logs..."
  mkdir -p "$(dirname "$log_file")"
  touch "$log_file"
  vpnserver execsvc & tail -n 0 -f "$log_file"
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

# called when the script exits
on_exit() {
  stop_server
  save_backup_files
}

# entrypoint of this script
main() {
  test_env SCRIPT_NAME INIT_SCRIPT
  load_backup_files
  test_capabilities
  init_server
  save_backup_files
  trap on_exit EXIT
  start_server
}

main "$@"
