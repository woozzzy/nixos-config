# Body of a writeShellApplication: set -euo pipefail and shellcheck are already on.
#
# jail: run COMMAND in a bubblewrap sandbox where
#   - ROOT (the project/workspace) is the only writable path, bound at its real location
#   - HOME is ROOT/.jail/NAME/INSTANCE, so every harness's "global" dir is per-instance
#   - /nix/store, /etc, /run/current-system are read-only; nothing else from the host exists
#   - the environment is cleared except for an explicit allow-list
#   - anything installed inside the instance (~/.local/bin, npm -g) shadows the host

usage() {
    cat <<'EOF'
jail [-n NAME] [-i INSTANCE] [-r ROOT] [-e VAR]... [-t] [-s] [-g] COMMAND [ARGS...]
jail ls [ROOT]

  -n NAME      state namespace          (default: basename of COMMAND)
  -i INSTANCE  instance within NAME     (default: default)
  -r ROOT      writable root            (default: $JAIL_ROOT, else nearest ancestor with .jail/,
                                         else git toplevel, else $PWD)
  -e VAR       pass VAR through from the host env (also: JAIL_ENV="A B")
  -t           temporary: discard instance state on exit
  -s           share the host ssh agent
  -g           expose the GPU

State lives in ROOT/.jail/NAME/INSTANCE and is HOME inside the jail.
EOF
}

find_root() {
    local d=$PWD
    while [[ $d != / ]]; do
        [[ -d $d/.jail ]] && { echo "$d"; return; }
        d=$(dirname "$d")
    done
    git rev-parse --show-toplevel 2>/dev/null || echo "$PWD"
}

name='' instance=default root=${JAIL_ROOT:-} temp=0 ssh=0 gpu=0
pass=()
# shellcheck disable=SC2206
[[ -n ${JAIL_ENV:-} ]] && pass+=($JAIL_ENV)

if [[ ${1:-} == ls ]]; then
    root=$(realpath "${2:-${root:-$(find_root)}}")
    [[ -d $root/.jail ]] && find "$root/.jail" -mindepth 2 -maxdepth 2 -type d -printf '%P\n'
    exit 0
fi

while getopts ":n:i:r:e:tsgh" opt; do
    case $opt in
        n) name=$OPTARG ;;
        i) instance=$OPTARG ;;
        r) root=$OPTARG ;;
        e) pass+=("$OPTARG") ;;
        t) temp=1 ;;
        s) ssh=1 ;;
        g) gpu=1 ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done
shift $((OPTIND - 1))
[[ $# -gt 0 ]] || { usage; exit 1; }

name=${name:-$(basename "$1")}
root=$(realpath "${root:-$(find_root)}")
cwd=$(realpath "$PWD")
[[ $cwd == "$root" || $cwd == "$root"/* ]] || { echo "jail: $cwd is outside root $root" >&2; exit 1; }

if (( temp )); then
    state=$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/jail-$name.XXXXXX")
    trap 'rm -rf "$state"' EXIT
else
    state=$root/.jail/$name/$instance
fi
mkdir -p "$state"/{.config,.cache,.local/share,.local/state,.local/bin,.npm-global/bin}

args=(
    --unshare-all --share-net --die-with-parent
    --proc /proc --dev /dev --tmpfs /tmp
    --ro-bind /nix/store /nix/store
    --ro-bind /nix/var/nix/daemon-socket /nix/var/nix/daemon-socket
    --ro-bind /run/current-system /run/current-system
    --ro-bind /etc /etc
    --ro-bind /bin /bin
    --ro-bind /usr /usr
    --bind "$root" "$root"
    --bind "$state" "$state"
    --chdir "$cwd"
    --clearenv
    --setenv HOME "$state"
    --setenv USER "${USER:-$(id -un)}"
    --setenv SHELL /run/current-system/sw/bin/zsh
    --setenv PATH "$state/.local/bin:$state/.npm-global/bin:$PATH"
    --setenv NPM_CONFIG_PREFIX "$state/.npm-global"
    --setenv XDG_CONFIG_HOME "$state/.config"
    --setenv XDG_CACHE_HOME "$state/.cache"
    --setenv XDG_DATA_HOME "$state/.local/share"
    --setenv XDG_STATE_HOME "$state/.local/state"
    --setenv NIX_REMOTE daemon
    --setenv SSL_CERT_FILE /etc/ssl/certs/ca-bundle.crt
    --setenv NIX_SSL_CERT_FILE /etc/ssl/certs/ca-bundle.crt
    --setenv TERMINFO_DIRS /run/current-system/sw/share/terminfo
    --setenv JAIL "$name/$instance"
)

for v in TERM COLORTERM LANG LC_ALL NIX_LD NIX_LD_LIBRARY_PATH "${pass[@]}"; do
    [[ -v $v ]] && args+=(--setenv "$v" "${!v}")
done

if (( ssh )) && [[ -n ${SSH_AUTH_SOCK:-} ]]; then
    args+=(--ro-bind "$SSH_AUTH_SOCK" "$SSH_AUTH_SOCK" --setenv SSH_AUTH_SOCK "$SSH_AUTH_SOCK")
fi

if (( gpu )); then
    for d in /dev/nvidia* /dev/dri; do
        [[ -e $d ]] && args+=(--dev-bind "$d" "$d")
    done
    args+=(--ro-bind /run/opengl-driver /run/opengl-driver)
fi

exec bwrap "${args[@]}" -- "$@"
