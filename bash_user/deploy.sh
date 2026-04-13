#!/usr/bin/env bash
set -euo pipefail

FILES=(
    .bash_prompt
    .bash_aliases
    .bash_functions
    .inputrc
    .dircolors
    .bash_portable.md
)

usage() {
    printf 'Usage: %s [-u user] [-f extra_file] host1 [host2 ...]\n' "$(basename "$0")" >&2
    printf '  -u user: deploy to /home/user (default: $USER)\n' >&2
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
        if [[ "$f" == *.sh ]]; then chmod_cmd+="chmod +x /home/$deploy_user/${f##*/}; "; fi
    done
}

stream_archive() {
    tar czf - -C "$script_dir" -- "${all_files[@]}"
}

deploy_local() {
    local home_dir="/home/$deploy_user"
    if [[ "$deploy_user" == "$USER" ]]; then
        stream_archive | tar xzf - -C "$home_dir"
        if [[ -n "$chmod_cmd" ]]; then bash -c "$chmod_cmd"; fi
    else
        stream_archive | sudo -u "$deploy_user" tar xzf - -C "$home_dir"
        if [[ -n "$chmod_cmd" ]]; then sudo bash -c "$chmod_cmd"; fi
    fi
}

deploy_remote() {
    local host="$1"
    local remote_cmd="tar xzf - -C ~"
    if [[ -n "$chmod_cmd" ]]; then remote_cmd+=" && $chmod_cmd"; fi
    stream_archive | ssh "$deploy_user@$host" "$remote_cmd"
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
extra_files=()
deploy_user="$USER"

while getopts ":u:f:" opt; do
    case "$opt" in
        u) deploy_user="$OPTARG" ;;
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
    printf '[%s] -> /home/%s\n' "$host" "$deploy_user"
    if [[ "$host" == "." ]]; then deploy_local; else deploy_remote "$host"; fi
    printf '[%s] OK (%d files)\n' "$host" "${#all_files[@]}"
done
