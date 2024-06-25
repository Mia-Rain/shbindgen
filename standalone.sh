[ -x "./bindgen.sh" ] || ${ERR:?}
./bindgen.sh "$@"
while [ "$1" ]; do
  case "$1" in
    "conf="*) conf="${1#*=}";;
  esac
  shift 1
done
[ "$conf" -a -e "$conf" ] && {
  . "$conf"
  type source && source "$conf"
  # use source if the shell supports it
  # if I'm not wrong source is required for some extensions in some shells 
}
[ "$standalone" ] && {
  printf '%s\n' "$standalone"
}