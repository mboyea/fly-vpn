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
  test_env SCRIPT_NAME
  # ? vpnserver start
  # ? wait_for_server_startup
  # ? vpnserver stop
  # ? wait_for_server_shutdown
}

main "$@"

# TODO start server

# TODO wait for server to come up (while)

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

# TODO stop server

# TODO wait for server to shut down (while)
