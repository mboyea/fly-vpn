{
  pkgs,
  name,
  version,
  server,
}: let
  _name = "${name}-docker-image";
  tag = version;
  # update base image using variables from:
  #   xdg-open https://hub.docker.com/_/busybox/tags
  #   nix-shell -p nix-prefetch-docker
  #   nix-prefetch-docker --quiet --image-name busybox --image-tag stable --image-digest sha256:_
  baseImage = pkgs.dockerTools.pullImage {
    imageName = "busybox";
    imageDigest = "sha256:7c3c3cea5d4d6133d6a694d23382f6a7b32652f23855abdba3eb039ca5995447";
    sha256 = "0k9ypllg4lmwd1a370z8n3awf5fpvlwwq355hmrfjwlmvqarjmjr";
    finalImageName = "busybox";
    finalImageTag = "stable";
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
    contents = [ server ];
    config = {
      Entrypoint = [ "${pkgs.lib.getExe server}" ];
      Cmd = [];
      ExposedPorts = {
        "5555/tcp" = {};
        "992/tcp" = {};
        "443/tcp" = {};
      };
    };
  };
}
