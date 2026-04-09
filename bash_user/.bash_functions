__interactive_shell() {
    [[ $- == *i* ]] && [[ -t 0 ]] && [[ -t 1 ]]
}

__log_dir_history() {
    __interactive_shell && printf '%s\n' "$PWD" >> "$HOME/.dir_history"
}

cd() {
    if [[ $# -eq 0 ]] && __interactive_shell; then
        local dirs=()
        mapfile -t dirs < <(find . -maxdepth 1 -type d -not -path . -not -name ".*" 2>/dev/null | sed 's|^\./||' | sort)

        local link_names=() link_display=()
        while IFS= read -r link; do
            local name
            name=$(basename "$link")
            if [[ -d "$link" ]]; then
                link_names+=("$name")
                link_display+=("$name"$'\t-> '"$(readlink "$link")")
            fi
        done < <(find . -maxdepth 1 -type l -not -name ".*" 2>/dev/null | sort)

        local all_names=("${dirs[@]}" "${link_names[@]}")

        if [[ ${#all_names[@]} -eq 0 ]]; then
            builtin cd .
        elif [[ ${#all_names[@]} -eq 1 ]]; then
            builtin cd "${all_names[0]}" && __log_dir_history
        else
            local dir_color link_color reset
            dir_color=$(printf '\033[%sm' "$(echo "$LS_COLORS" | tr ':' '\n' | grep '^di=' | cut -d= -f2)")
            link_color=$(printf '\033[%sm' "$(echo "$LS_COLORS" | tr ':' '\n' | grep '^ln=' | cut -d= -f2)")
            reset=$'\033[0m'

            local selected
            selected=$(
                {
                    printf '%s\n' "${dir_color}..${reset}"
                    for d in "${dirs[@]}"; do printf '%s\n' "${dir_color}${d}${reset}"; done
                    for t in "${link_display[@]}"; do printf '%s\n' "${link_color}${t}${reset}"; done
                } | fzf --ansi --height=40% --reverse --prompt="Select directory: "
            )

            if [[ -n "$selected" ]]; then
                local dir_name
                dir_name=$(printf '%s' "$selected" | sed 's/\x1b\[[0-9;]*m//g' | cut -f1)
                builtin cd "$dir_name" && __log_dir_history
            fi
        fi
    else
        builtin cd "$@" && __log_dir_history
    fi
}

__hist_widget() {
    local max_lines="${HIST_VIEW_SIZE:-200}"
    local selected
    selected=$(history | tac | head -n "$max_lines" | sed 's/^ *[0-9]* *//' | fzf --height=40% --reverse --prompt="History: ")
    if [[ -n "$selected" ]]; then
        READLINE_LINE="$selected"
        READLINE_POINT=${#selected}
    fi
}

dh() {
    local hist_file="$HOME/.dir_history"
    local max_lines="${DIR_HISTORY_SIZE:-100}"
    [[ -f "$hist_file" ]] || return

    local deduped
    mapfile -t deduped < <(tac "$hist_file" | awk '!seen[$0]++' | while IFS= read -r d; do [[ -d "$d" ]] && echo "$d"; done)

    local line_count
    line_count=$(wc -l < "$hist_file")
    if (( line_count > 2 * max_lines )); then
        printf '%s\n' "${deduped[@]}" | tac > "$hist_file"
    fi

    local dir_color reset
    dir_color=$(printf '\033[%sm' "$(echo "$LS_COLORS" | tr ':' '\n' | grep '^di=' | cut -d= -f2)")
    reset=$'\033[0m'

    local selected
    selected=$(printf '%s\n' "${deduped[@]}" | head -n "$max_lines" | \
        while IFS= read -r d; do printf '%s\n' "${dir_color}${d}${reset}"; done | \
        fzf --ansi --height=40% --reverse --prompt="Dir history: ")

    if [[ -n "$selected" ]]; then
        local dir_name
        dir_name=$(printf '%s' "$selected" | sed 's/\x1b\[[0-9;]*m//g')
        builtin cd "$dir_name" && echo "$PWD" >> "$hist_file"
    fi
}

rm() {
    if [[ $# -eq 0 ]] && __interactive_shell; then
        local selected_item
        selected_item=$(ls -1p --color=always 2>/dev/null | fzf --ansi --height=40% --reverse --prompt="Select item to remove: ")
        if [[ -n "$selected_item" ]]; then
            local item_name
            item_name=$(printf '%s' "$selected_item" | sed 's/\x1b\[[0-9;]*m//g; s|/$||')
            if [[ -d "$item_name" ]]; then
                echo "rmdir $item_name"
                command rmdir -- "$item_name"
            else
                echo "rm $item_name"
                command rm -- "$item_name"
            fi
        fi
    else
        command rm "$@"
    fi
}

del() {
    if [[ $# -eq 0 ]]; then
        local selected_item
        selected_item=$(ls -1pA --color=always 2>/dev/null | fzf --ansi --height=40% --reverse --prompt="Select item to delete: ")
        if [[ -n "$selected_item" ]]; then
            local item_name
            item_name=$(printf '%s' "$selected_item" | sed 's/\x1b\[[0-9;]*m//g; s|/$||')
            echo "rm -rf $item_name"
            command rm -rf -- "$item_name"
        fi
    else
        command rm -rf -- "$@"
    fi
}

list() {
    if [[ $# -eq 0 ]]; then
        local selected_file
        selected_file=$(ls -1p -a --color=always 2>/dev/null | grep -v '/$' | fzf --ansi --height=40% --reverse --prompt="Select file to view: ")
        if [[ -n "$selected_file" ]]; then
            less -- "$(printf '%s' "$selected_file" | sed 's/\x1b\[[0-9;]*m//g')"
        fi
    else
        less -- "$@"
    fi
}

ffind() {
    local OPTIND opt
    local opt_subdirs=0 opt_case_file=0 opt_case_text=0 opt_bare=0 opt_hidden=0
    local text_pattern=""

    while getopts ":sIcibHt:" opt; do
        case "$opt" in
            s) opt_subdirs=1 ;;
            I) opt_case_file=1 ;;
            c|i) opt_case_text=1 ;;
            b) opt_bare=1 ;;
            H) opt_hidden=1 ;;
            t) text_pattern="$OPTARG" ;;
            :) echo "ffind: -$OPTARG requires an argument" >&2; return 1 ;;
            \?) echo "ffind: unknown option: -$OPTARG" >&2; return 1 ;;
        esac
    done
    shift $((OPTIND - 1))

    local search_dir="." file_pattern

    case $# in
        0)
            echo "ffind: missing filename pattern" >&2
            echo 'Usage: ffind [-sIibH] [-t "pattern"] [dir] "filename_pattern"' >&2
            return 1
            ;;
        1) file_pattern="$1" ;;
        2)
            if [[ ! -d "$1" ]]; then
                echo "ffind: '$1' is not a directory" >&2
                echo 'Usage: ffind [-sIibH] [-t "pattern"] [dir] "filename_pattern"' >&2
                return 1
            fi
            search_dir="$1"
            file_pattern="$2"
            ;;
        *)
            echo "ffind: too many arguments ($# non-option args; quote the pattern?)" >&2
            echo 'Usage: ffind [-sIibH] [-t "pattern"] [dir] "filename_pattern"' >&2
            return 1
            ;;
    esac

    local name_flag=-name
    [[ $opt_case_file -eq 1 ]] && name_flag=-iname

    local find_args=("$search_dir")
    [[ $opt_subdirs -eq 0 ]] && find_args+=(-maxdepth 1)

    if [[ $opt_hidden -eq 0 ]]; then
        find_args+=("(" -mindepth 1 -name ".*" -prune ")" -o "(" "$name_flag" "$file_pattern" -not -type d -print ")")
    else
        find_args+=("$name_flag" "$file_pattern" -not -type d)
    fi

    while IFS= read -r filepath; do
        local fullpath
        fullpath=$(realpath -- "$filepath")

        if [[ -z "$text_pattern" ]]; then
            echo "$fullpath"
        elif [[ $opt_bare -eq 1 ]]; then
            local grep_opts=("-qE")
            [[ $opt_case_text -eq 1 ]] && grep_opts+=("-i")
            grep "${grep_opts[@]}" -- "$text_pattern" "$fullpath" 2>/dev/null && echo "$fullpath"
        else
            local grep_text_opts=("-m1" "-IE")
            local grep_count_opts=("-cE")
            local grep_bin_opts=("-qE")
            [[ $opt_case_text -eq 1 ]] && grep_text_opts+=("-i") && grep_count_opts+=("-i") && grep_bin_opts+=("-i")
            local match count
            if match=$(grep "${grep_text_opts[@]}" -- "$text_pattern" "$fullpath" 2>/dev/null); then
                count=$(grep "${grep_count_opts[@]}" -- "$text_pattern" "$fullpath" 2>/dev/null)
                echo "$fullpath [$count]"
                echo "  $match"
                echo
            elif grep "${grep_bin_opts[@]}" -- "$text_pattern" "$fullpath" 2>/dev/null; then
                echo "$fullpath"
                echo "  (binary)"
                echo
            fi
        fi
    done < <(find "${find_args[@]}" 2>/dev/null)
}
