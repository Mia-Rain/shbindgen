#!/bin/sh
nl="
"
space=" "
[ $ZSH_VERSION ] && setopt sh_word_split
shcat() {
  IFS=""
  while read -r line || [ "$line" ]; do
    printf '%s\n' "$line"
  done
# might be better as for IFS loop
# but some shells have issues with IFS
}
while [ "$1" ]; do
  case "$1" in
    "conf="*) conf="${1#*=}";;
    "disable="*) 
    eval "${1#*=}=disabled"
    eval [ \$"${1#*=}" = "disabled" ] || {
      printf '%s\n' "!! ERROR: eval failed to disable function ${1#*=}" >&2
      printf '%s\n' "!! ERROR: This is likely an issue with the shell at /bin/sh" >&2
      exit 1
    }
    ;;
    # the above evals were tested with oksh, zsh, freebsd sh, and bash
    # and confirmed working
    # this is again a fail safe for future proofing
    ##
    # using eval is simpler later
    # as if a list is used, it has to be parsed
    # where with eval we can just do the above again
    # this spawns a subshell; but prevents additional loops for list parsing
  esac
  shift 1
done
# attempt to handle arguments
# getopts is NOT posix thus a while [ "$1" ] and shift loop is used
# this moves through each argument and handles it
# all arguments are lost after handling
##
[ "$conf" -a -e "$conf" ] && {
  . "$conf"
  type source && source "$conf"
  # use source if the shell supports it
  # if I'm not wrong source is required for some extensions in some shells 
}
# load config

[ "$src" ] || src="./src"
[ -e "$src" ] || {
  printf '%s\n' "!! ERROR: there is nothing to compile..? no ./src or folder at ${src:-\$src}" >&2
  exit 1
}
[ "$lib" ] || lib="./lib"
# libraries aren't needed
find () {
  for file in "${1%/}/"* "${1%/}/."*; do
    file="${file#./}"; file="${file%/}"; file="${file#/}"; file="${file#${1#./}}"
    # bunch of fixes for formatting
    case "${file#/}" in
      '.'|'..'|'.*'|'*') continue ;;
    esac
    # case check for .. & . & * & .*
    [ -d "${1%/}/${file#/}" ] && {
      dirname="${1%/}/${file#/}"
      [ "$2" ] && dirname="${2:+${2}/}${dirname#./}"
      # all these checks are for freebsd sh
      # a case check is likely better here tbh
      printf '%s\n' "${dirname}"
      cd "${dirname#${2}/}"
      find "./" "${dirname}"
      cd ../
    } || {
      filename="${1%/}/${file#/}" 
      [ "$2" ] && filename="${2:+${2}/}${filename#./}"
      # basename is ${filename##*/}
      basename="${filename##*/}"
      printf '%s\n' "$filename" #printf '%s\n' "${basename}() {"
    }
  done
}
# this has some weird issues with cd
# if run where $1 is a dir
comp() {
  [ -e "$1/" ] || return 1
  ### find()
  [ "$orig_path" ] || orig_path="$PWD";
  [ ! "$1" ] && return 1;
  [ -e "$1" ] || return 1
  for file in "${1%/}/"* "${1%/}/."*; do
    file="${file#./}"; file="${file%/}"; file="${file#/}"; file="${file#${1#./}}"
    # bunch of fixes for formatting
    case "${file#/}" in
      '.'|'..'|'.*'|'*') continue ;;
    esac
    # case check for .. & . & * & .*
    [ -d "${1%/}/${file#/}" ] && {
      # all these checks are for freebsd sh
      # a case check is likely better here tbh
      pwd="$PWD"; find "${1%/}/${file#/}"; cd "$pwd" 
    } || { 
      # file is "${1%/}/${file#/}"
      filename="${1%/}/${file#/}"
      # basename is ${filename##*/}
      basename="${filename##*/}"
      eval [ \$"${basename#*=}" = "disabled" ] 2>/dev/null && continue
      printf '%s\n' "${basename}() {"
      case "$(shcat < $filename)" in
        *"exit"*)
          IFS=""
          while read -r line || [ "$line" ]; do
            case "$line" in
              *"exit"*)
                line="${line%%exit*}return${line##*exit}"
                printf '%s\n' "$line"
                ;;
              *) printf '%s\n' "$line";;
            esac
          done << EOF
$(shcat < "$filename")
EOF
        ;;
        *) shcat < "$filename";;
      esac
      printf '%s\n' "}"
    }
  done
  ###

  # basically have to do a find(1) here
  # technically for looping over find() is slower than
  ## running with the loop
}
# compile data in "$1/" into functions and output
comp "$lib"
comp "$src"