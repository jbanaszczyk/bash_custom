#!/usr/bin/env bash
set -euo pipefail

FILES=(
    .bash_custom
    .bash_prompt
    .bash_aliases
    .bash_functions
    .inputrc
    .dircolors
    .bash_portable.md
)

usage() {
    printf 'Usage: %s [-f extra_file] host1 [host2 ...]\n' "$(basename "$0")" >&2
    printf '  -f can be used multiple times, e.g.: -f dedup_history.sh\n' >&2
    exit 1
}

validate_files() {
    for file in "${all_files[@]}"; do
        [[ -f "$script_dir/$file" ]] || { printf 'Missing file: %s\n' "$script_dir/$file" >&2; exit 1; }
    done
}

build_chmod_cmd() {
    chmod_cmd=""
    for f in "${all_files[@]}"; do
        if [[ "$f" == *.sh ]]; then chmod_cmd+="chmod +x /root/${f##*/}; "; fi
    done
}

# owner root:root - tar run as root restores the owner stored in the archive
stream_archive() {
    local shared=()    # repo root, not in git - deployed only if present
    [[ -f "$script_dir/../.hostname_aliases" ]] && shared=(-C "$script_dir/.." .hostname_aliases)
    tar czf - --owner=0 --group=0 --numeric-owner -C "$script_dir" "${all_files[@]}" "${shared[@]}"
}

deploy_local() {
    stream_archive | sudo tar xzf - -C /root
    if [[ -n "$chmod_cmd" ]]; then sudo bash -c "$chmod_cmd"; fi
}

# Two steps: upload to a temp file, then extract with ssh -t (sudo needs a terminal for the password)
deploy_remote() {
    local host="$1" tmp
    tmp=$(stream_archive | ssh "$USER@$host" 'f=$(mktemp) && cat > "$f" && echo "$f"')
    local remote_cmd="tar xzf $tmp -C /root"
    if [[ -n "$chmod_cmd" ]]; then remote_cmd+=" && $chmod_cmd"; fi
    ssh -t "$USER@$host" "sudo bash -c \"$remote_cmd\"; rc=\$?; rm -f $tmp; exit \$rc"
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
extra_files=()

while getopts ":f:" opt; do
    case "$opt" in
        f) extra_files+=("$OPTARG") ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))
(( $# > 0 )) || usage

all_files=("${FILES[@]}" "${extra_files[@]}")
chmod_cmd=""

validate_files
build_chmod_cmd

for host in "$@"; do
    printf '[%s] -> /root\n' "$host"
    if [[ "$host" == "." ]]; then deploy_local; else deploy_remote "$host"; fi
    printf '[%s] OK (%d files)\n' "$host" "${#all_files[@]}"
done
