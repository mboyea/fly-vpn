# see https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/networking/softether.nix

# return true if user is root user
isUserRoot() {
  [ "$(id -u)" == "0" ]
}

# print an error message to the console
echo_error() {
  echo "Error in $SCRIPT_NAME:" "$@" 1>&2;
}

# if the listed env variables aren't found, exit with an error message
test_env() {
  # disable exit on undefined variable use
  set +u
  # for each env variable
  while [[ $# -gt 0 ]]; do
    # check that env variable is defined
    if [ -z "${!1}" ]; then
      echo_error The required environment variable "$1" is not defined
      exit 1
    fi
    shift
  done
  # enable exit on undefined variable use
  set -u
}

# load the env file if it exists
load_env_file() {
  # if git is not installed, return
  if ! [ -x "$(command -v git)" ]; then
    return
  fi
  # if current directory is not a git directory, return
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    return
  fi
  # go to top-level of git directory
  base_dir="$(git rev-parse --show-toplevel)"
  cd "$base_dir"
  # load .env file if it exists
  if [ -r "$ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1091 source=/dev/null
    source "$ENV_FILE"
    set +a
  fi
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
  internet_network_device="$(ip addr show | grep -o '[0-9]:.*:.*BROADCAST.*MULTICAST.*UP.*LOWER_UP.*' | sed -e 's/[0-9]*: \(.*\):.*/\1/' | sed -e 's/\(.*\)@.*/\1/')"
  if [[ "${is_use_production_cn_arg-}" -eq 1 ]]; then
    mkdir -p /etc
    cat << EOF > /etc/udhcpd.conf
# see https://udhcp.busybox.net/udhcpd.conf

# The start and end of the IP lease block

start 		192.168.0.20	 #default: 192.168.0.20
end		    192.168.0.254	 #default: 192.168.0.254

# The interface that udhcpd will use

interface	$internet_network_device		#default: eth0

# If remaining is true (default) udhcpd will store the time
# remaining for each lease in the udhcpd leases file. This is
# for embedded systems that cannot keep time between reboots.

remaining yes

# location of DHCP files

lease_file /var/lib/misc/udhcpd.leases
pidfile    /var/run/udhcpd.pid

# DNS servers that connected devices will use. Use Google DNS.

opt dns 8.8.8.8 8.8.4.4

# IP addresses for the access point

opt router 192.168.0.1
opt subnet 255.255.255.0
opt domain local

# 10 days of lease period
opt lease 864000
EOF
    mkdir -p /var/lib/misc
    touch /var/lib/misc/udhcpd.leases
    mkdir -p /var/run
    touch /var/run/udhcpd.pid
    mkdir -p /etc/network
    cat << EOF > /etc/network/interfaces
auto lo

iface lo inet loopback
iface eth0 inet dhcp

iface wlan0 inet static
address 192.168.0.1
netmask 255.255.255.0
EOF
    # ! OKAYYY THIS SUCKS
    # ? WHY even bother doing this shit when there's a premade Docker image provided by Softether? Just restart the project and consume that.
    udhcpd
  fi
  vpnbridge start
}

# init server; start cli
postStart() {
  echo "--- SETTING SERVER PASSWORD ---"
  { echo "$SOFTETHER_PASS"; echo "$SOFTETHER_PASS"; echo "$SOFTETHER_PASS"; } | vpncmd "$server_ip_port" /SERVER /CMD ServerPasswordSet
  echo "--- INITIALIZING SERVER CONFIG ---"
  {
    echo "SstpEnable yes"
    echo "HubCreate ${HUB_NAME:-flyvpn} /PASSWORD:${HUB_PASS:-}"
    echo "BridgeCreate ${HUB_NAME:-flyvpn} /DEVICE:$internet_network_device"
    #! echo "Hub ${HUB_NAME:-flyvpn}"
    #! echo "SecureNatEnable"
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
  # determine the preferred common name (cn)
  cn="${cn_override-$server_ip}"
  if [[ "${is_use_production_cn_arg-}" -eq 1 ]]; then
    cn="$PRODUCTION_CN"
  fi
  # the server cert is valid of the cn matches the stored cn
  if [ -f $DATA_DIR/vpnserver/cn.txt ]; then
    last_cn=$(<$DATA_DIR/vpnserver/cn.txt)
  else
    last_cn=""
  fi
  if [[ "$cn" != "$last_cn" ]]; then
    echo "!!! NOTICE: SERVER CN CHANGED, UPDATING SERVER CERT !!!"
    vpncmd "$server_ip_port" /SERVER "/PASSWORD:$SOFTETHER_PASS" /CMD ServerCertRegenerate "$cn"
    # shellcheck disable=SC2174
    mkdir -m0700 -p "$DATA_DIR/vpnserver"
    echo "$cn" > "$DATA_DIR/vpnserver/cn.txt"
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
  if [[ "${is_keep_alive_arg-}" -eq 1 ]]; then
    echo "Keeping server online..."
    sleep infinity
  fi
}

# stop server
stop() {
  vpnbridge stop
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

# interpret arguments passed to this script
interpret_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --override-cn)
        cn_override="$2"
        shift
        shift
      ;;
      --use-production-cn)
        is_use_production_cn_arg=1
        test_env PRODUCTION_CN
        shift
      ;;
      --keep-alive)
        is_keep_alive_arg=1
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
  # shellcheck disable=SC2086
  set -- "$@" $ADDITIONAL_CLI_ARGS # set additional CLI args passed by Nix
  test_env SCRIPT_NAME
  interpret_args "$@"
  test_env ENV_FILE
  load_env_file
  test_env DATA_DIR SOFTETHER_INSTALL_DIR SOFTETHER_PASS USER_PASS_PAIRS
  trap onExit EXIT
  preStart
  start
  # delay to ensure server is ready to accept connections
  sleep 0.2
  postStart
}

main "$@"
