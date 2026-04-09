#!/usr/bin/env bash
set -euo pipefail

FILES=(
    .bash_prompt
    .bash_aliases
    .bash_functions
    .inputrc
    .dircolors
)

usage() {
    printf 'Usage: %s [-f extra_file] host1 [host2 ...]\n' "$(basename "$0")" >&2
    printf '  -f can be used multiple times, e.g.: -f .bashrc_ -f dedup_history.sh\n' >&2
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
        [[ "$f" == *.sh ]] && chmod_cmd+="chmod +x /root/${f##*/}; "
    done
}

stream_archive() {
    tar czf - -C "$script_dir" -- "${all_files[@]}"
}

deploy_local() {
    stream_archive | sudo tar xzf - -C /root
    [[ -n "$chmod_cmd" ]] && sudo bash -c "$chmod_cmd"
}

deploy_remote() {
    local host="$1"
    local remote_cmd="tar xzf - -C /root"
    [[ -n "$chmod_cmd" ]] && remote_cmd+=" && $chmod_cmd"
    stream_archive | ssh "$USER@$host" "sudo bash -c \"$remote_cmd\""
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
done
