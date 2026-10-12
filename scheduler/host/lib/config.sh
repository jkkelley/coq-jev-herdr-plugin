#!/usr/bin/env bash
# scheduler/host/lib/config.sh - what the host wrappers know of the scheduler's two config files, sourced by run.sh and
# run-exec.sh. The Go loader is the authority on the files (SPEC-16.G); the wrappers read only the few keys that decide a
# podman flag, a mount or a directory, with jq, and resolve the variables of SPEC-16.G g-vars the same way the loader does:
#   ${HOME}, ${ENV:NAME}        from the wrapper's environment; unset is exit 3 naming it
#   ${repo} ${state_dir} ${host_repo}   the file's own key of that name, resolved in turn
# Anything else in ${...} is exit 3 naming it, as in the loader: a typo never becomes an empty path.
#   cfg_raw FILE KEY            the key's raw value (keys are flat, a dot is part of the name); missing is exit 3
#   cfg_resolve FILE STRING     STRING with every variable resolved
#   cfg_env_names FILE          every NAME the file references as ${ENV:NAME}, one per line, sorted, unique
# CFG_REPO, when set, is what ${repo} resolves to instead of the file's repo key: run.sh mounts the repository in the
# container at its host path, so on the host side of the wrapper the two are the same directory.
# Every nested call ends in `|| exit $?`: a command substitution does not inherit errexit, so without it a failed inner
# resolve would hand back an empty string and the outer one would carry on.
cfg_die() { local c=$1; shift; printf '%s: %s\n' "${CFG_WHO:-scheduler-host}" "$*" >&2; exit "$c"; }

cfg_raw() {
  local v
  v=$(jq -er --arg k "$2" 'if has($k) then .[$k] | if type == "array" then .[] else tostring end else error("missing") end' "$1" 2>/dev/null) ||
    cfg_die 3 "$(basename "$1"): key $2 missing"
  printf '%s\n' "$v"
}

cfg_resolve() {
  local file=$1 s=$2 name ev rep depth=0
  while [[ $s =~ \$\{([^}]*)\} ]]; do
    name=${BASH_REMATCH[1]}
    depth=$((depth + 1)); [ "$depth" -le 32 ] || cfg_die 3 "$(basename "$file"): variables nest too deep in $2"
    case $name in
      HOME) [ -n "${HOME:-}" ] || cfg_die 3 "HOME unset"; rep=$HOME ;;
      ENV:*) ev=${name#ENV:}; [[ $ev =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || cfg_die 3 "$(basename "$file"): bad name \${$name}"
        [ -n "${!ev:-}" ] || cfg_die 3 "$(basename "$file"): ENV:$ev is unset"
        rep=${!ev} ;;
      repo | state_dir | host_repo)
        if [ "$name" = repo ] && [ -n "${CFG_REPO:-}" ]; then rep=$CFG_REPO
        else rep=$(cfg_raw "$file" "$name") || exit $?; rep=$(cfg_resolve "$file" "$rep") || exit $?; fi ;;
      *) cfg_die 3 "$(basename "$file"): unknown variable \${$name} in $2" ;;
    esac
    s=${s/"\${$name}"/"$rep"}  # rep quoted: bash 5.2 patsub_replacement reads an unquoted & as the match
  done
  printf '%s\n' "$s"
}

cfg_env_names() { grep -o '\${ENV:[A-Za-z_][A-Za-z0-9_]*}' "$1" | sed 's/^\${ENV:\(.*\)}$/\1/' | sort -u; }
