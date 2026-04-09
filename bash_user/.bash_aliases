alias getip='hostname -I | awk "{print \$1}"'
alias ..='cd ..'
alias ...='cd ../..'
alias ~='cd $HOME'
alias full='realpath'
pshow() { echo "$PATH" | tr ':' '\n'; }
calc() { echo "$*" | bc -l; }
alias dir='ls -la --color=auto'
alias cls='clear'
alias md='mkdir'
