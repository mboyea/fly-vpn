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

# start the server and wait for it to come online
start_server() {
  echo "Starting server..."
  vpnserver start > /dev/null
  flags=$-
  # if e flag (exit when a program throws an error) was set, disable it
  if [[ $flags =~ e ]]; then set +e; fi
  # until vpncmd works, sleep for 100ms
  until [[ $(vpncmd localhost /SERVER /CMD ServerInfoGet) ]] > /dev/null; do
    sleep 0.1
  done
  # if e flag was set, re-enable it
  if [[ $flags =~ e ]]; then set -e; fi
  echo "Server started."
}

# stop the server and wait for it to shutdown
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

# initialize the server config
init_server() {
  echo "Initializing server..."
  # TODO: IMITATE ALL SIOMIZ/SOFTETHERVPN FUNCTIONS
  # TODO: IMITATE ALL ARCHIVE/SERVER.SH FUNCTIONS
  echo "Server initialized."
}

# entrypoint of this script
main() {
  test_env SCRIPT_NAME
  trap stop_server EXIT
  start_server
  init_server
}

main "$@"

# TODO: ServerCipherSet DHE-RSA-AES256-SHA
# TODO: version=About | head -3 | tail -1 | sed 's/^/# /;'
# ! TODO IPsecEnable /L2TP:yes /L2TPRAW:yes /ETHERIP:no /PSK:${PSK} /DEFAULTHUB:DEFAULT
# TODO: HUB DEFAULT SecureNatEnable
# TODO: HUB DEFAULT NatSet /MTU:$MTU /LOG:no /TCPTIMEOUT:3600 /UDPTIMEOUT:1800
# TODO enable openvpn
# TODO: ProtoOptionsSet OpenVPN /NAME:Enabled /VALUE:True
# TODO: PortsUDPSet 1194
# TODO validate server cert and key
# TODO: OpenVpnMakeConfig openvpn.zip
# TODO extract and print openvpn.zip
# TODO: HUB LogDisable packet
# TODO: HUB LogDisable security
# TODO force user-mode SecureNAT
# TODO: HUB ExtOptionSet DisableIpRawModeSecureNAT /VALUE:true
# TODO: HUB ExtOptionSet DisableKernelModeSecureNAT /VALUE:true
# TODO load USER_PASS_PAIRS
# TODO load custom vpncmds from env variables
# TODO set HUB password
# TODO set SERVER password

# ? echo "--- SETTING SERVER PASSWORD ---"
# ? { echo "$SOFTETHER_PASS"; echo "$SOFTETHER_PASS"; echo "$SOFTETHER_PASS"; } | vpncmd "$server_ip_port" /SERVER /CMD ServerPasswordSet
# ? echo "--- INITIALIZING SERVER CONFIG ---"
# ? {
# ?   echo "SstpEnable yes"
# ?   echo "HubCreate ${HUB_NAME:-flyvpn} /PASSWORD:${HUB_PASS:-}"
# ?   echo "BridgeCreate ${HUB_NAME:-flyvpn} /DEVICE:$internet_network_device"
# ?   #! echo "Hub ${HUB_NAME:-flyvpn}"
# ?   #! echo "SecureNatEnable"
# ? } | vpncmd "$server_ip_port" /SERVER "/PASSWORD:$SOFTETHER_PASS"
# ? echo "--- CREATING SERVER USERS ---"
# ? if [[ -n "$USER_PASS_PAIRS" ]]; then
# ?   # create each user and set user passwords
# ?   for user_pass_pair in $USER_PASS_PAIRS; do
# ?     user="${user_pass_pair%%:*}"
# ?     pass="${user_pass_pair#*:}"
# ?     {
# ?       echo "Hub ${HUB_NAME:-flyvpn}"
# ?       echo "UserCreate $user /GROUP:none /REALNAME:none /NOTE:none"
# ?       echo "UserPasswordSet $user"
# ?       echo "$pass"; echo "$pass"
# ?     } | vpncmd "$server_ip_port" /SERVER "/PASSWORD:$SOFTETHER_PASS"
# ?   done
# ? fi
# ? echo "--- VERIFYING SERVER CERT ---"
# ? # determine the preferred common name (cn)
# ? cn="${cn_override-$server_ip}"
# ? if [[ "${is_use_production_cn_arg-}" -eq 1 ]]; then
# ?   cn="$PRODUCTION_CN"
# ? fi
# ? # the server cert is valid of the cn matches the stored cn
# ? if [ -f $DATA_DIR/vpnserver/cn.txt ]; then
# ?   last_cn=$(<$DATA_DIR/vpnserver/cn.txt)
# ? else
# ?   last_cn=""
# ? fi
# ? if [[ "$cn" != "$last_cn" ]]; then
# ?   echo "!!! NOTICE: SERVER CN CHANGED, UPDATING SERVER CERT !!!"
# ?   vpncmd "$server_ip_port" /SERVER "/PASSWORD:$SOFTETHER_PASS" /CMD ServerCertRegenerate "$cn"
# ?   # shellcheck disable=SC2174
# ?   mkdir -m0700 -p "$DATA_DIR/vpnserver"
# ?   echo "$cn" > "$DATA_DIR/vpnserver/cn.txt"
# ?   echo "!!! NOTICE: SERVER CERT HAS CHANGED, CLIENTS MUST UPDATE CERTS !!!"
# ? else
# ?   echo "Cert is valid."
# ? fi
# ? echo "--- GETTING SERVER CERT ---"
# ? server_cert=$(echo "/dev/stdout" | vpncmd "$server_ip_port" /SERVER "/PASSWORD:$SOFTETHER_PASS" /CMD ServerCertGet | sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p')
# ? echo "$server_cert" > "$DATA_DIR/vpnserver/fly-vpn-server.crt"
# ? echo "The common name (CN) to connect to the server with is: $cn"
# ? echo "The following cert was copied to $DATA_DIR/vpnserver/fly-vpn-server.crt:"
# ? echo "$server_cert"
# ? echo "--- STARTING SERVER CLI ---"
# ? # tail -f "$DATA_DIR/vpnserver/server_log/vpn_$(date +%Y%m%d).log" & \
# ? vpncmd "$server_ip_port" /SERVER "/PASSWORD:$SOFTETHER_PASS"
# ? if [[ "${is_keep_alive_arg-}" -eq 1 ]]; then
# ?   echo "Keeping server online..."
# ?   sleep infinity
# ? fi
