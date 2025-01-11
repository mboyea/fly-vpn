{
  pkgs,
  name,
  version,
}: let
  _name = "${name}-help-${version}";
in pkgs.writeShellApplication {
  name = _name;
  runtimeEnv = {
    SCRIPT_NAME = _name;
    PROJECT_NAME = name;
  };
  text = builtins.readFile ./help.sh;
}
