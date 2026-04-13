alias getip='hostname -I | awk "{print \$1}"'
alias ..='cd ..'
alias ...='cd ../..'
alias ~='cd $HOME'
alias full='realpath'
pshow() { echo "$PATH" | tr ':' '\n'; }
calc() { if [[ $# -eq 0 ]]; then bc -l; else printf '%s\n' "$*" | bc -l; fi; }
alias dir='ls -lah --color=auto'
alias cls='clear'
alias md='mkdir -p'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
