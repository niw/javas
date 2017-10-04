# javas requires /usr/libexec/java_home to switch java on OS X.
# See java_home (1).
if [[ ! -x /usr/libexec/java_home ]]; then
  return 1
fi

javas() {
  local version="$1"

  # Java version is begin 1.1 to 1.8, but Java 9 is 9.
  # So, only numbers less than 9 are interrupted as 1.x.
  case "$version" in
  [0-8] )
    version="1.$version"
    ;;
  esac
  readonly version

  if [[ -z $version ]]; then
    unset JAVA_HOME
  else
    export JAVA_HOME=$(/usr/libexec/java_home -v "$version")
  fi
  export JAVAS_JAVA_VERSION=$(java -version 2>&1|head -n1|cut -d'"' -f2)
}

# jvs means javas or java switch.
alias jvs=javas

_javas_cd_hook() {
  local current_dir="$(pwd -P)"
  local rcfile

  while : ; do
    if [[ -f "$current_dir/.javasrc" ]]; then
      rcfile="$current_dir/.javasrc"
      break
    fi
    if [[ -z "$current_dir" \
      || "$current_dir" = "$HOME" \
      || "$current_dir" = "/" \
      || "$current_dir" = "." ]]; then
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
  readonly rcfile

  if [[ ! "$javas_LAST_RC_FILE" = "$rcfile" ]]; then
    # Parse .javasrc
    # In future, this must be yaml or more handy format.
    javas "$(cat "$rcfile"|head -n1|cut -d' ' -f2)"
    export JAVAS_LAST_RC_FILE="$rcfile"
  fi
}

enable_javas_cd_hook() {
  # Only when we can use zsh chpwd_functions, use it.
  if [[ -n "$ZSH_VERSION" ]]; then
    autoload -Uz is-at-least
    if is-at-least 4.3.4 >/dev/null 2>&1; then
      # Force to read javasrc file first.
      export JAVAS_LAST_RC_FILE=
      _javas_cd_hook

      typeset -gaU chpwd_functions
      chpwd_functions+=_javas_cd_hook
      return
    fi
  fi
  return 1
}
