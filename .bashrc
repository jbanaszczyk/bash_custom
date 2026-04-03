# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Powerline style

# PS1="\[\e[32m\]➜\[\e[36m\]\u\[\e[0m\]@\[\e[35m\]\h\[\e[0m\] \[\e[33m\]\w\[\e[0m\] \[\e[31m\]\$(git branch 2>/dev/null | sed -n 's/* \(.*\)/\1/p')\[\e[0m\]\n\$ "

# Custom bash configuration - modular setup
if [ -f ~/.bash_prompt ]; then
    . ~/.bash_prompt
fi

if [ -f ~/.bash_functions ]; then
    . ~/.bash_functions
fi
