{
  pkgs,
  name,
  version,
  server,
}: let
  # podman pull docker.io/siomiz/softethervpn 
  # podman container run --tty --interactive --privileged siomiz/softethervpn
  _name = "${name}-docker-image";
  tag = version;
  # update base image using variables from:
  #   xdg-open https://hub.docker.com/r/siomiz/softethervpn/tags
  #   nix-shell -p nix-prefetch-docker
  #   nix-prefetch-docker --image-name siomiz/softethervpn --image-tag latest --image-digest sha256:_
  baseImage = pkgs.dockerTools.pullImage {
    imageName = "siomiz/softethervpn";
    imageDigest = "sha256:d5697e4c3862b32a3ff517035eb329dce60305c7b1f17a191c4c6e15d0f4febd";
    sha256 = "1xpnjv4khd4d4ckn83idlqj2hyyrhqszgb0qhhcd26rw2m552d6d";
    finalImageName = "siomiz/softethervpn";
    finalImageTag = "latest";
    os = "linux";
    arch = "amd64";
  };
in {
  inherit version tag;
  name = _name;
  stream = pkgs.dockerTools.streamLayeredImage {
    inherit tag;
    name = _name;
    fromImage = baseImage;
    # contents = [ server ];
    config = {
      Entrypoint = [ "/entrypoint.sh" ]; # https://github.com/siomiz/SoftEtherVPN/blob/master/copyables/entrypoint.sh
      Cmd = [ "/usr/bin/vpnserver" "execsvc" ]; # https://github.com/siomiz/SoftEtherVPN/blob/master/Dockerfile
      # Cmd = [ "/usr/local/bin/vpnserver" "execsvc" ];
      # ExposedPorts = {
      #   "5555/tcp" = {};
      #   "992/tcp" = {};
      #   "443/tcp" = {};
      # };
    };
  };
}
