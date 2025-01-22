{
  pkgs,
  name,
  version,
}: let
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
  entrypoint = import ./entrypoint.nix { inherit pkgs version; name = _name; };
in {
  inherit version tag;
  name = _name;
  # see https://github.com/moby/docker-image-spec/blob/main/spec.md
  stream = pkgs.dockerTools.streamLayeredImage {
    inherit tag;
    name = _name;
    fromImage = baseImage;
    contents = [ entrypoint ];
    enableFakechroot = true;
    fakeRootCommands = ''
      ln -sf '${pkgs.lib.getExe entrypoint}' /entrypoint.sh
    '';
    config = {
      Entrypoint = [ "/entrypoint.sh" ];
      Cmd = [];
      ExposedPorts = {
        "443/tcp" = {};
        "992/tcp" = {};
        "5555/tcp" = {};
        "500/udp" = {};
        "1194/udp" = {};
        "1701/udp" = {};
        "4500/udp" = {};
      };
      Volumes = {
        # TODO: add volumes
        # "/path/to/data/dir" = {};
      };
    };
  };
}
