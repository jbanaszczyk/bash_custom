__cd_root() {
    cd /
}

/() {
    __cd_root
}

list() {
    if command -v batcat >/dev/null 2>&1; then
        batcat "$@"
    else
        less "$@"
    fi
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
