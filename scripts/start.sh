echo_error() {
  echo "Error in $SCRIPT_NAME:" "$@" 1>&2;
}

interpret_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      native)
        : "${script:="$START_VPN_SERVER"}"
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

main() {
  # set additional CLI args from env variable
  set -- "$@" "$ADDITIONAL_CLI_ARGS"
  # interpret CLI args
  interpret_args "$@"
  # if script was found in CLI args, run it
  if [[ -n "${script:-}" ]]; then
    "$script" "${unrecognized_args[@]}"
  # otherwise if no CLI args defined, run the default script
  elif [[ ! ${unrecognized_args[*]} ]]; then
    "$START_VPN_SERVER"
  # otherwise throw error that CLI args are invalid
  else
    echo_error "Invalid arguments:" "${unrecognized_args[@]}"
    exit 1
  fi
}

main "$@"
