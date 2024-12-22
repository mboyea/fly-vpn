# see https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/networking/softether.nix

# return true if user is root user
isUserRoot() {
  [ "$(id -u)" == "0" ]
}

# install into data dir
preStart() {
  for d in vpnserver vpnbridge vpnclient vpncmd; do
    # shellcheck disable=SC2174
    mkdir -m0700 -p "$DATA_DIR/$d"
    if ! test -e "$DATA_DIR/$d/hamcore.se2"; then
      install -m0600 "$SOFTETHER_DIR$DATA_DIR/$d/hamcore.se2" "$DATA_DIR/$d/hamcore.se2"
    fi
    if test -e "$SOFTETHER_DIR$DATA_DIR/$d/init.txt"; then
      install -m0600 "$SOFTETHER_DIR$DATA_DIR/$d/init.txt" "$DATA_DIR/$d/init.txt"
    fi
    rm -rf "${DATA_DIR:?}/$d/$d"
    ln -s "$SOFTETHER_DIR$DATA_DIR/$d/$d" "$DATA_DIR/$d/$d"
  done
}

# start server
start() {
  server_url="$(vpnserver start | grep -Eo '(https)://[a-zA-Z0-9./?=_%:-]*:5555')"
  server_ip="${server_url#https://}"
}

# init server; start cli
postStart() {
  echo "--- SETTING SERVER PASSWORD ---"
  { echo "$SOFTETHER_PWD"; echo "$SOFTETHER_PWD"; echo "$SOFTETHER_PWD"; } | vpncmd "$server_ip" /SERVER "/CMD" "ServerPasswordSet"
  echo "--- INITIALIZING SERVER CONFIG ---"
  vpncmd "$server_ip" /SERVER "/PASSWORD:$SOFTETHER_PWD" "/IN:$DATA_DIR/vpnserver/init.txt"
  echo "--- STARTING SERVER CLI ---"
  vpncmd "$server_ip" /SERVER "/PASSWORD:$SOFTETHER_PWD"
}

# stop server
stop() {
  vpnserver stop
}

# uninstall from data dir
postStop() {
  for d in vpnserver vpnbridge vpnclient vpncmd; do
    rm -rf "${DATA_DIR:?}/$d/$d"
  done
}

# called when script exits
onExit() {
  echo
  stop
  postStop
}

# called when script starts
main() {
  if ! isUserRoot; then
    sudo "$0" "$@"
    exit
  fi
  trap onExit EXIT
  preStart
  start
  # delay to ensure server is ready to accept connections
  sleep 0.2
  postStart
}

main "$@"
