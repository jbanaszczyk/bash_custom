__interactive_shell() {
    [[ $- == *i* ]] && [[ -t 0 ]] && [[ -t 1 ]]
}

# fzf preview (list, rm, del, use, Ctrl+T): dir -> ls, file -> batcat; ANSI colors = terminal palette
__fzf_preview='[ -d {} ] && ls -la --color=always -- {} || batcat --theme=ansi -n --color=always --line-range :300 -- {}'

__log_dir_history() {
    __interactive_shell && printf '%s\n' "$PWD" >> "$HOME/.dir_history"
}

# Source ./.direnv after entering a directory - only a regular file, owned by you, executable
__source_direnv() {
    if [[ -f .direnv && -O .direnv && -x .direnv ]]; then
        . ./.direnv
    fi
}

# builtin cd + log to ~/.dir_history + source ./.direnv
__cd() {
    # ~~ / ~~/sub -> $PROJECT_DIR (bash expands only ~ itself)
    [[ $1 == "~~" || $1 == "~~/"* ]] && set -- "${PROJECT_DIR:-$HOME}${1#"~~"}" "${@:2}"
    builtin cd "$@" || return
    __log_dir_history
    __source_direnv
    return 0
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
            __cd "${all_names[0]}"
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
                __cd "$dir_name"
            fi
        fi
    else
        __cd "$@"
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
        __cd "$dir_name"
    fi
}

# RM_TRASH=1 and gio installed: rm moves to the trash (same trash as Dolphin)
__rm_trash() { [[ ${RM_TRASH:-0} == 1 ]] && command -v gio >/dev/null; }

rm() {
    if [[ $# -eq 0 ]] && __interactive_shell; then
        local items=() item_name
        mapfile -t items < <(ls -1p --color=always 2>/dev/null |
            fzf -m --ansi --height=40% --reverse --preview "$__fzf_preview" --prompt="Select items to remove (Tab marks): " |
            sed 's/\x1b\[[0-9;]*m//g; s|/$||')
        for item_name in "${items[@]}"; do
            if __rm_trash; then
                echo "trash $item_name"
                gio trash "./$item_name"
            elif [[ -d "$item_name" ]]; then
                echo "rmdir $item_name"
                command rmdir -- "$item_name"
            else
                echo "rm $item_name"
                command rm -- "$item_name"
            fi
        done
    elif __rm_trash; then
        # rm-style options (-r -f -i ...) are skipped - directories go to the trash anyway
        while [[ $1 == -* ]]; do [[ $1 == -- ]] && { shift; break; }; shift; done
        # ./ instead of -- : gio treats "--" before a -name as a file name
        gio trash "${@/#-/./-}"
    else
        command rm "$@"
    fi
}

del() {
    if [[ $# -eq 0 ]]; then
        local items=() item_name
        mapfile -t items < <(ls -1pA --color=always 2>/dev/null |
            fzf -m --ansi --height=40% --reverse --preview "$__fzf_preview" --prompt="Select items to delete (Tab marks): " |
            sed 's/\x1b\[[0-9;]*m//g; s|/$||')
        for item_name in "${items[@]}"; do
            echo "rm -rf $item_name"
            command rm -rf -- "$item_name"
        done
    else
        command rm -rf "$@"
    fi
}

# TCC SELECT: pick with fzf (Tab marks several), then
#   use              -> selection to the clipboard (shell-quoted, space-separated)
#   use cmd .. {} .. -> cmd once per item, {} replaced by the name (also inside a word: {}.bak)
#   use cmd ..       -> cmd once, all items appended
# List: ls -A of the current dir (dirs first, colored), or stdin when piped: find . -name '*.log' | use rm {}
use() {
    local items=() f a per_item=0
    mapfile -t items < <(
        if [[ -t 0 ]]; then ls -1Ap --group-directories-first --color=always; else cat; fi |
            fzf -m --ansi --height=40% --reverse --preview "$__fzf_preview" --prompt="use: " |
            sed 's/\x1b\[[0-9;]*m//g; s|/$||; s|^-|./-|')    # ./-name: not taken as an option
    (( ${#items[@]} )) || return 1

    if (( $# == 0 )); then
        local text
        text=$(printf '%q ' "${items[@]}"); text=${text% }
        clip "$text"
        printf 'clipboard: %s\n' "$text"
        return
    fi
    for a; do [[ $a == *"{}"* ]] && per_item=1; done
    if (( per_item )); then
        for f in "${items[@]}"; do
            local cmd=("${@//"{}"/"$f"}")    # quoted replacement: & in names stays literal
            printf '%q ' "${cmd[@]}"; echo
            "${cmd[@]}" < /dev/tty    # stdin may be the used-up pipe: vi, nano need the keyboard
        done
    else
        printf '%q ' "$@" "${items[@]}"; echo
        "$@" "${items[@]}" < /dev/tty
    fi
}

list() {
    local viewer
    if command -v batcat >/dev/null 2>&1; then
        viewer=(batcat --theme=ansi --pager 'less -n')
    else
        viewer=(less)
    fi

    if [[ $# -eq 0 ]]; then
        local selected_file
        selected_file=$(
            ls -1p -a --color=always 2>/dev/null |
            grep -v '/$' |
            fzf --ansi --height=40% --reverse --preview "$__fzf_preview" --prompt="Select file to view: "
        )
        if [[ -n "$selected_file" ]]; then
            "${viewer[@]}" -- "$(printf '%s' "$selected_file" | sed 's/\x1b\[[0-9;]*m//g')"
        fi
    else
        "${viewer[@]}" "$@"
    fi
}

__cd_root() {
    local git_root home="$HOME"

    git_root="$(git rev-parse --show-toplevel 2>/dev/null)"
    if [[ -n "$git_root" ]]; then
        cd -- "$git_root"
    elif [[ "$PWD" == "$home" || "$PWD" == "$home/"* ]]; then
        cd -- "$home"
    else
        cd /
    fi
}

/() {
    __cd_root
}

# Copy stdin (or arguments) to the local clipboard via OSC 52 - works locally and over ssh
clip() {
    local data
    if [[ $# -gt 0 ]]; then data="$*"; else data=$(cat); fi
    printf '\e]52;c;%s\a' "$(printf '%s' "$data" | base64 -w0)" > /dev/tty
}

mcd() {
    mkdir -p -- "$1" && cd -- "$1"
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

############

netstat() {
    if [[ $# -eq 0 ]]; then
        command netstat -ltnp
    else
        command netstat "$@"
    fi
}

############

load_completion() {
    [[ -n ${BASH_COMPLETION_VERSINFO-} ]] && return 0
    [ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
}
