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
configure_settings() {
  echo "Initializing server..."
  # TODO gracefully handle server password changes
  # set the server password
  { echo "$SOFTETHER_PASS"; echo "$SOFTETHER_PASS"; echo "$SOFTETHER_PASS"; } \
    | vpncmd localhost /SERVER /CMD ServerPasswordSet > /dev/null
  # set the server configuration
  {
    # weak ciphers are enabled by default, see https://forum.vpngate.net/viewtopic.php?t=64385
    echo "ServerCipherSet DHE-RSA-AE256-SHA"
    # enable connections via L2TP over IPsec
    echo "IPsecEnable /L2TP:yes /L2TPRAW:yes /ETHERIP:no /PSK:$IPSEC_PSK /DEFAULTHUB:DEFAULT"
    # enable connections via SSTP
    echo "SstpEnable yes"
    # enable connections via OpenVPN
    # ! OpenVpnEnable may be broken; see https://github.com/SoftEtherVPN/SoftEtherVPN/discussions/1882
    # ? echo "OpenVpnEnable yes /PORTS:1194"
    echo "ProtoOptionsSet OpenVPN /Name:Enabled /Value:True"
    echo "PortsUDPSet 1194"
    # enter hub mode
    echo "Hub DEFAULT"
    # set hub password
    echo "SetHubPassword $HUB_PASS"
    # disable verbose logs
    echo "LogDisable packet"
    echo "LogDisable security"
    # enable SecureNAT (internal NAT and DHCP server)
    echo "SecureNatEnable"
    # set NAT settings
    echo "NatSet /MTU:$NAT_MTU /LOG:no /TCPTIMEOUT:$NAT_TCP_TIMEOUT /UDPTIMEOUT:$NAT_UDP_TIMEOUT"
    # force user-mode SecureNAT
    echo "ExtOptionSet DisableIpRawModeSecureNAT /VALUE:true"
    echo "ExtOptionSet DisableKernelModeSecureNAT /VALUE:true"
  } | vpncmd localhost /SERVER "/PASSWORD:$SOFTETHER_PASS" > /dev/null
  echo "Server initialized."
}

# create the server users
create_users() {
  echo "Creating users..."
  # if no user data is given, do nothing
  if [[ -z "$USER_PASS_PAIRS" ]]; then
    echo "No users to create."
    return
  fi
  # create each user and set their password
  for user_pass_pair in $USER_PASS_PAIRS; do
    user="${user_pass_pair%%:*}"
    pass="${user_pass_pair#*:}"
    {
      echo "Hub DEFAULT"
      echo "UserCreate $user /GROUP:none /REALNAME:none /NOTE:none"
      echo "UserPasswordSet $user"
      echo "$pass"
      echo "$pass"
    } | vpncmd localhost /SERVER "/PASSWORD:$SOFTETHER_PASS" > /dev/null
    echo "User \"$user\" created."
  done
  echo "Done creating users."
}

# generate the server authentication certificate and SSL private key
generate_cert_and_key() {
  echo "Validating server certificate..."
  flags=$-
  cn="$COMMON_NAME"
  cn_file="$(realpath /opt)/store/cn.txt"
  cert_file="$(realpath /opt)/store/server.crt"
  key_file="$(realpath /opt)/store/server.key"
  if [[ $flags =~ e ]]; then set +e; fi
  { last_cn=$(< "$cn_file"); } 2>&-
  if [[ $flags =~ e ]]; then set -e; fi
  # if the existing certificate and key are valid, use them
  if [[ "$cn" == "$last_cn" && -s "$cert_file" && -s "$key_file" ]]; then
    vpncmd localhost /SERVER "/PASSWORD:$SOFTETHER_PASS" /CMD \
      ServerCertSet "/LOADCERT:$cert_file" "/LOADKEY:$key_file" > /dev/null
    echo "Server cert is valid."
    return
  fi
  # generate a new server certificate & key
  echo "Server cert isn't valid."
  echo "Generating new server cert..."
  vpncmd localhost /SERVER "/PASSWORD:$SOFTETHER_PASS" /CMD \
    ServerCertRegenerate "$cn" > /dev/null
  # store the new server certificate
  cert=$( \
    echo "/dev/stdout" \
    | vpncmd localhost /SERVER "/PASSWORD:$SOFTETHER_PASS" /CMD ServerCertGet \
    | sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' \
  )
  mkdir -p "$(dirname "$cert_file")"
  echo "$cert" > "$cert_file"
  # store the new server key
  key=$( \
    echo "/dev/stdout" \
    | vpncmd localhost /SERVER "/PASSWORD:$SOFTETHER_PASS" /CMD ServerKeyGet \
    | sed -n '/-----BEGIN PRIVATE KEY-----/,/-----END PRIVATE KEY-----/p' \
  )
  mkdir -p "$(dirname "$key_file")"
  echo "$key" > "$key_file"
  # store the new server common name (cn)
  mkdir -p "$(dirname "$cn_file")"
  echo "$cn" > "$cn_file"
  echo "Server cert has been changed; Clients must download the new cert."
}

# generate the openvpn configuration file
generate_openvpn_config() {
  openvpn_config_zip_file="$(realpath /opt)/store/openvpn.zip"
  openvpn_config_file="$(realpath /opt)/store/openvpn.ovpn"
  # generate the openvpn configuration in .zip format
  echo "Generating new OpenVPN config..."
  cd "$(dirname "$openvpn_config_zip_file")"
  vpncmd localhost /SERVER "/PASSWORD:$SOFTETHER_PASS" /CMD \
    OpenVpnMakeConfig "$(basename "$openvpn_config_zip_file")" > /dev/null
  cd - > /dev/null
  # convert the openvpn configuration to .ovpn format
  # shellcheck disable=SC2035
  unzip -p "$openvpn_config_zip_file" *_l3.ovpn > "$openvpn_config_file"
  # remove "#" comments, "\r", and empty lines from the openvpn configuration
  sed -i '/^#/d;s/\r//;/^$/d' "$openvpn_config_file"
  echo "Created OpenVPN config file."
}

# entrypoint of this script
main() {
  test_env SCRIPT_NAME SOFTETHER_PASS HUB_PASS IPSEC_PSK COMMON_NAME
  : "${NAT_MTU:="1500"}"
  : "${NAT_TCP_TIMEOUT:="3600"}"
  : "${NAT_UDP_TIMEOUT:="1800"}"
  : "${USER_PASS_PAIRS:=""}"
  trap stop_server EXIT
  start_server
  configure_settings
  create_users
  generate_cert_and_key
  generate_openvpn_config
}

main "$@"
