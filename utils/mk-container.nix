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
  imageArgs ? [],
  podmanArgs ? [],
  # ? https://forums.docker.com/t/solution-required-for-nginx-emerg-bind-to-0-0-0-0-443-failed-13-permission-denied/138875/2
  # ! Linux does not allow an unprivileged user to bind software to a port below 1024.
  # ! It is not a restriction introduced by docker or containers in general.
  # ! People usually use 8080/8443 instead and map host port 80 to 8080 and host port 443 to 8443.
  # ! However, in the case you need to use a low port number for expected behavior, the option to run as root is provided here.
  runAsRootUser ? false,
  preStart ? "",
}: pkgs.writeShellApplication {
  name = "${name}-${image.name}-mk-container-${version}";
  runtimeInputs = [
    pkgs.podman
  ];
  text = preStart + ''
    isUserRoot() {
      [ "$(id -u)" == "0" ]
    }
    if "${pkgs.lib.trivial.boolToString runAsRootUser}"; then
      if ! isUserRoot; then
        sudo "$0" "$@"
        exit
      fi
    fi
    echo "> ${image.stream} | podman image load"
    ${image.stream} | podman image load
    echo "> podman container run --tty --interactive ${pkgs.lib.strings.concatStringsSep " " podmanArgs} localhost/${image.name}:${image.tag} ${pkgs.lib.strings.concatStringsSep " " imageArgs}"
    podman container run --tty --interactive ${pkgs.lib.strings.concatStringsSep " " podmanArgs} localhost/${image.name}:${image.tag} ${pkgs.lib.strings.concatStringsSep " " imageArgs}
  '';
}
