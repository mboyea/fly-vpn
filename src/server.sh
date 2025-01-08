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
      install -m0600 "$SOFTETHER_INSTALL_DIR$DATA_DIR/$d/hamcore.se2" "$DATA_DIR/$d/hamcore.se2"
    fi
    rm -rf "${DATA_DIR:?}/$d/$d"
    ln -s "$SOFTETHER_INSTALL_DIR$DATA_DIR/$d/$d" "$DATA_DIR/$d/$d"
  done
}

# start server
start() {
  server_url="$(vpnserver start | grep -Eo '(https)://[a-zA-Z0-9./?=_%:-]*:5555')"
  server_ip_port="${server_url#https://}"
  server_ip="${server_ip_port%:5555}"
}

# init server; start cli
postStart() {
  echo "--- SETTING SERVER PASSWORD ---"
  { echo "$SOFTETHER_PASS"; echo "$SOFTETHER_PASS"; echo "$SOFTETHER_PASS"; } | vpncmd "$server_ip_port" /SERVER /CMD ServerPasswordSet
  echo "--- INITIALIZING SERVER CONFIG ---"
  {
    echo "SstpEnable yes"
    echo "HubCreate ${HUB_NAME:-flyvpn} /PASSWORD:${HUB_PASS:-}"
    echo "Hub ${HUB_NAME:-flyvpn}"
    echo "SecureNatEnable"
  } | vpncmd "$server_ip_port" /SERVER "/PASSWORD:$SOFTETHER_PASS"
  echo "--- CREATING SERVER USERS ---"
  if [[ -n "$USER_PASS_PAIRS" ]]; then
    # create each user and set user passwords
    for user_pass_pair in $USER_PASS_PAIRS; do
      user="${user_pass_pair%%:*}"
      pass="${user_pass_pair#*:}"
      {
        echo "Hub ${HUB_NAME:-flyvpn}"
        echo "UserCreate $user /GROUP:none /REALNAME:none /NOTE:none"
        echo "UserPasswordSet $user"
        echo "$pass"; echo "$pass"
      } | vpncmd "$server_ip_port" /SERVER "/PASSWORD:$SOFTETHER_PASS"
    done
  fi
  echo "--- VERIFYING SERVER CERT ---"
  # common name (cn) is CN_OVERRIDE if set, otherwise it's the server IP
  cn="${CN_OVERRIDE-$server_ip}"
  if [ -f $DATA_DIR/vpnserver/cn.txt ]; then
    last_cn=$(<$DATA_DIR/vpnserver/cn.txt)
  else
    last_cn=""
  fi
  if [[ "$cn" != "$last_cn" ]]; then
    echo "!!! NOTICE: SERVER CN CHANGED, UPDATING SERVER CERT !!!"
    vpncmd "$server_ip_port" /SERVER "/PASSWORD:$SOFTETHER_PASS" /CMD ServerCertRegenerate "$cn"
    # shellcheck disable=SC2174
    mkdir -m0700 -p $DATA_DIR/vpnserver
    echo "$cn" > $DATA_DIR/vpnserver/cn.txt
    echo "!!! NOTICE: SERVER CERT HAS CHANGED, CLIENTS MUST UPDATE CERTS !!!"
  else
    echo "Cert is valid."
  fi
  echo "--- GETTING SERVER CERT ---"
  server_cert=$(echo "/dev/stdout" | vpncmd "$server_ip_port" /SERVER "/PASSWORD:$SOFTETHER_PASS" /CMD ServerCertGet | sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p')
  echo "$server_cert" > "$DATA_DIR/vpnserver/fly-vpn-server.crt"
  echo "The common name (CN) to connect to the server with is: $cn"
  echo "The following cert was copied to $DATA_DIR/vpnserver/fly-vpn-server.crt:"
  echo "$server_cert"
  echo "--- STARTING SERVER CLI ---"
  # tail -f "$DATA_DIR/vpnserver/server_log/vpn_$(date +%Y%m%d).log" & \
  vpncmd "$server_ip_port" /SERVER "/PASSWORD:$SOFTETHER_PASS"
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
  echo "IP ADDRESS: $(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1)"
}

# called when script exits
onExit() {
  echo
  stop
  postStop
}

interpret_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --override-cn)
        CN_OVERRIDE="$2"
        shift
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

# called when script starts
main() {
  if ! isUserRoot; then
    sudo "$0" "$@"
    exit
  fi
  # set additional CLI args from env variable
  set -- "$@" "$ADDITIONAL_CLI_ARGS"
  interpret_args "$@"
  trap onExit EXIT
  preStart
  start
  # delay to ensure server is ready to accept connections
  sleep 0.2
  postStart
}

main "$@"
