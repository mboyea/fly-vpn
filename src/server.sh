# see https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/networking/softether.nix

isUserRoot() {
  [ "$(id -u)" == "0" ]
}

preStart() {
  for d in vpnserver vpnbridge vpnclient vpncmd; do
    if ! test -e "$DATA_DIR/$d"; then
      # shellcheck disable=SC2174
      mkdir -m0700 -p "$DATA_DIR/$d"
      install -m0600 "$SOFTETHER_DIR$DATA_DIR/$d/hamcore.se2" "$DATA_DIR/$d/hamcore.se2"
    fi
    rm -rf "${DATA_DIR:?}/$d/$d"
    ln -s "$SOFTETHER_DIR$DATA_DIR/$d/$d" "$DATA_DIR/$d/$d"
  done
}

start() {
  url="$(vpnserver start | grep -Eo '(https)://[a-zA-Z0-9./?=_%:-]*:5555')"
  ip_address="${url#https://}"
  {
    echo "1"
    echo "$ip_address"
    cat
  } | vpncmd
}

stop() {
  vpnserver stop
  # vpnbridge stop
}

postStop() {
  for d in vpnserver vpnbridge vpnclient vpncmd; do
    rm -rf "${DATA_DIR:?}/$d/$d"
  done
}

onExit() {
  echo
  stop
  postStop
}

main() {
  if ! isUserRoot; then
    sudo "$0" "$@"
    exit
  fi
  trap onExit EXIT
  preStart
  start
}

main "$@"
