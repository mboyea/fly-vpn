#--------------------------------
# Author : Matthew Boyea
# Origin : https://github.com/mboyea/fly-vpn
# Description : use podman to start a docker image with Nix
# Nix Usage : 
#  server = pkgs.writeShellApplication {
#    name = "${name}-server-${version}";
#    runtimeInputs = [
#      pkgs.uutils-coreutils-noprefix
#    ];
#    text = ''
#      echo "Hello, world!"
#      tail -f /dev/null
#    '';
#  };
#  serverImage = let
#    _name = "${name}-docker-image";
#     tag = version;
#     baseImage = null;
#  in {
#    name = _name;
#    inherit version tag;
#    stream = pkgs.dockerTools.streamLayeredImage {
#      name = _name;
#      inherit tag;
#      fromImage = baseImage;
#      contents = [ server ];
#      config = {
#        Cmd = [ "${pkgs.lib.getExe server}" ];
#        ExposedPorts = {
#          "5555/tcp" = {};
#        };
#      };
#    };
#  };
#  serverContainer = pkgs.callPackage ./mk-container.nix {
#    inherit pkgs name version;
#    image = serverImage;
#    podmanArgs = [
#      "--publish"
#      "5555:5555"
#    ];
#  };
#--------------------------------
{
  pkgs,
  name,
  version,
  image,
  podmanArgs ? [],
  defaultImageArgs ? [],
  # ? https://forums.docker.com/t/solution-required-for-nginx-emerg-bind-to-0-0-0-0-443-failed-13-permission-denied/138875/2
  # ! Linux does not allow an unprivileged user to bind software to a port below 1024.
  # ! It is not a restriction introduced by docker or containers in general.
  # ! People usually use 8080 and 8443 instead, mapping host port 80 to 8080 and host port 443 to 8443.
  # ! However, in the case you need to use a low port number for expected behavior, the option to run as root is provided here.
  # ! Note that this is insecure when combined with --privileged and a malicious image.
  runAsRootUser ? false,
  preStart ? "",
  postStop ? "",
}: pkgs.writeShellApplication {
  name = "${name}-${image.name}-mk-container-${version}";
  runtimeInputs = [
    pkgs.podman
  ];
  text = ''
    # return true if user is root user
    isUserRoot() {
      [ "$(id -u)" == "0" ]
    }

    # if this should run as the root user, make sure user is the root user
    if "${pkgs.lib.trivial.boolToString runAsRootUser}"; then
      if ! isUserRoot; then
        sudo "$0" "$@"
        exit
      fi
    fi

    ${preStart}

    # cleanup when this script exits
    on_exit() {
      ${postStop}
      :
    }
    trap on_exit EXIT

    echo_exec() {
      ( set -x; "$@" )
    }

    echo_exec ${image.stream} | echo_exec podman image load

    echo_exec podman container run --tty --interactive \
      ${pkgs.lib.strings.concatStringsSep " " podmanArgs} \
      localhost/${image.name}:${image.tag} \
      "$( \
        if [ "$#" -eq 0 ]; then \
          echo ${pkgs.lib.strings.concatStringsSep " " defaultImageArgs}; \
        else \
          echo "$@"; \
        fi \
      )"
  '';
}
