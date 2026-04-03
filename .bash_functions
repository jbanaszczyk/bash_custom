fzf_cd() {
    local selected_dir
    selected_dir=$(find . -maxdepth 1 -type d -not -path . -not -name "." 2>/dev/null | sed 's|^\./||' | sort | fzf --height=40% --reverse --prompt="Select directory: ")
    if [[ -n "$selected_dir" ]]; then
        cd "$selected_dir"
        printf '\e[2K\r\e[A\e[2K\r'
    fi
}

cd() {
    if [[ $# -eq 0 ]]; then
        fzf_cd
    else
        builtin cd "$@"
    fi
}

fzf_cd_up() {
    if [[ -z "$READLINE_LINE" ]]; then
        cd ..
        printf '\e[2K\r\e[A\e[2K\r'
    else
        READLINE_LINE="cd .."
        READLINE_POINT=${#READLINE_LINE}
    fi
}

fzf_cd_down() {
    if [[ -z "$READLINE_LINE" ]]; then
        fzf_cd
    else
        READLINE_LINE="fzf_cd"
        READLINE_POINT=${#READLINE_LINE}
    fi
}

rm() {
    if [[ $# -eq 0 ]]; then
        local selected_item
        selected_item=$((find . -maxdepth 1 -type d -not -name "." 2>/dev/null | sed 's|^\./||'; find . -maxdepth 1 -type f 2>/dev/null | sed 's|^\./||') | sort | fzf --height=40% --reverse --prompt="Select item to remove: ")
        if [[ -n "$selected_item" ]]; then
            if [[ -d "$selected_item" ]]; then
                echo "rmdir $selected_item"
                command rmdir "$selected_item"
            else
                echo "rm $selected_item"
                command rm "$selected_item"
            fi
        fi
    else
        command rm "$@"
    fi
}

del() {
    if [[ $# -eq 0 ]]; then
        local selected_item
        selected_item=$((find . -maxdepth 1 -type d -not -name "." 2>/dev/null | sed 's|^\./||'; find . -maxdepth 1 -type f 2>/dev/null | sed 's|^\./||') | sort | fzf --height=40% --reverse --prompt="Select item to delete: ")
        if [[ -n "$selected_item" ]]; then
            echo "rm -rf $selected_item"
            command rm -rf "$selected_item"
        fi
    else
        command rm -rf "$@"
    fi
}

list() {
    if [[ $# -eq 0 ]]; then
        local selected_file
        selected_file=$(find . -maxdepth 1 -type f 2>/dev/null | sed 's|^\./||' | sort | fzf --height=40% --reverse --prompt="Select file to view: ")
        if [[ -n "$selected_file" ]]; then
            less "$selected_file"
        fi
    else
        less "$@"
    fi
}

calc() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: calc <expression>"
        return 1
    else
        echo "$*" | bc -l
    fi
}

full() {
    if [[ $# -eq 0 ]]; then
        local selected_file
        selected_file=$(find . -maxdepth 1 -type f 2>/dev/null | sed 's|^\./||' | sort | fzf --height=40% --reverse --prompt="Select file to show full path: ")
        if [[ -n "$selected_file" ]]; then
            realpath "$selected_file" 2>/dev/null
        fi
    else
        realpath "$1" 2>/dev/null || echo "File not found: $1" >&2
    fi
}

ffull() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: ffull <pattern>..."
    else
        local pattern
        for pattern in "$@"; do
            find . -name "*$pattern*" 2>/dev/null
        done
    fi
}
