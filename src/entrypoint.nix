{
  pkgs,
  name,
  version,
} : let
  _name = "${name}-entrypoint-${version}";
  help = let __name = "${_name}-help"; in pkgs.writeShellApplication {
    name = __name;
    runtimeEnv = {
      SCRIPT_NAME = __name;
      PROJECT_NAME = "${name}-entrypoint";
    };
    text = builtins.readFile ./help.sh;
  };
  init = let __name = "${_name}-init"; in pkgs.writeShellApplication {
    name = __name;
    runtimeEnv = {
      SCRIPT_NAME = __name;
    };
    text = builtins.readFile ./init.sh;
  };
  run = let __name = "${_name}-run"; in pkgs.writeShellApplication {
    name = __name;
    runtimeEnv = {
      SCRIPT_NAME = __name;
    };
    text = builtins.readFile ./run.sh;
  };
  start = let __name = "${_name}-start"; in pkgs.writeShellApplication {
    name = __name;
    runtimeEnv = {
      SCRIPT_NAME = __name;
      INIT_SCRIPT = pkgs.lib.getExe init;
    };
    text = builtins.readFile ./start.sh;
  };
in pkgs.writeShellApplication {
  name = _name;
  runtimeEnv = {
    SCRIPT_NAME = _name;
    HELP_SCRIPT = pkgs.lib.getExe help;
    INIT_SCRIPT = pkgs.lib.getExe init;
    RUN_SCRIPT = pkgs.lib.getExe run;
    START_SCRIPT = pkgs.lib.getExe start;
  };
  text = builtins.readFile ./entrypoint.sh;
}
