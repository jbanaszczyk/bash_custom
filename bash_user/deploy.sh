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
    printf 'Usage: %s [-u user] [-f extra_file] host1 [host2 ...]\n' "$(basename "$0")" >&2
    printf '  -u user: deploy to ~user on the target host via sudo -u (default: $USER)\n' >&2
    printf '  -f can be used multiple times, e.g.: -f dedup_history.sh\n' >&2
    exit 1
}

validate_files() {
    for file in "${all_files[@]}"; do
        [[ -f "$script_dir/$file" ]] || { printf 'Missing file: %s\n' "$script_dir/$file" >&2; exit 1; }
    done
}

# Extract stdin into ~deploy_user, chmod +x the *.sh files; ~user is expanded by the shell that runs it
build_extract_cmd() {
    extract_cmd="cd ~$deploy_user && tar xzf -"
    for f in "${all_files[@]}"; do
        if [[ "$f" == *.sh ]]; then extract_cmd+=" && chmod +x ${f##*/}"; fi
    done
}

stream_archive() {
    local shared=()    # repo root, not in git - deployed only if present
    [[ -f "$script_dir/../.hostname_aliases" ]] && shared=(-C "$script_dir/.." .hostname_aliases)
    tar czf - -C "$script_dir" "${all_files[@]}" "${shared[@]}"
}

deploy_local() {
    if [[ "$deploy_user" == "$USER" ]]; then
        stream_archive | bash -c "$extract_cmd"
    else
        stream_archive | sudo -u "$deploy_user" bash -c "$extract_cmd"
    fi
}

deploy_remote() {
    local host="$1" tmp
    if [[ "$deploy_user" == "$USER" ]]; then
        stream_archive | ssh "$USER@$host" "$extract_cmd"
    else
        # Two steps: upload to a temp file, then extract with ssh -t (sudo needs a terminal for the password)
        tmp=$(stream_archive | ssh "$USER@$host" 'f=$(mktemp) && cat > "$f" && echo "$f"')
        ssh -t "$USER@$host" "sudo -u $deploy_user bash -c '$extract_cmd' < $tmp; rc=\$?; rm -f $tmp; exit \$rc"
    fi
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
validate_files
build_extract_cmd

for host in "$@"; do
    printf '[%s] -> ~%s\n' "$host" "$deploy_user"
    if [[ "$host" == "." ]]; then deploy_local; else deploy_remote "$host"; fi
    printf '[%s] OK (%d files)\n' "$host" "${#all_files[@]}"
done
