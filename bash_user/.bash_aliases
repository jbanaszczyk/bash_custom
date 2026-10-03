alias ..='cd ..'
alias ...='cd ../..'
alias ~='cd $HOME'
alias ~~='cd -- "${PROJECT_DIR:-$HOME}"'
alias full='realpath'
truename() { realpath -ms -- "${@:-.}"; }
pshow() { echo "$PATH" | tr ':' '\n'; }
calc() { if [[ $# -eq 0 ]]; then bc -l; else printf '%s\n' "$*" | bc -l; fi; }
alias dir='ls -lah --color=auto'
alias cls='clear'
alias md='mkdir -p'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
