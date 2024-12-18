{
  pkgs,
  name,
  version
}: pkgs.writeShellApplication {
  name = "${name}-server-${version}";
  text = builtins.readFile ./server.sh;
}
