{
  pkgs,
  name,
  version,
  server ? pkgs.callPackage ./server.nix { inherit name version; }
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
  name = _name;
  inherit version tag;
  stream = pkgs.dockerTools.streamLayeredImage {
    name = _name;
    inherit tag;
    fromImage = baseImage;
      # server.override {
      #   envVars = envVars // {
      #     CN_OVERRIDE = envVars.PRODUCTION_CN;
      #   };
      # };
    contents = [ # TODO inject ip address as CN
      server
    ];
    config = {
      Entrypoint = [ "${pkgs.lib.getExe server}" ];
      ExposedPorts = {
        "5555/tcp" = {};
        "992/tcp" = {};
        "443/tcp" = {};
      };
    };
  };
}
