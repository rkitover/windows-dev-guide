export LC_ALL=en_DE.UTF-8
export PAGER=less

stty -ixon 2>/dev/null

ulimit -c unlimited

set -o notify
set -o ignoreeof

# Remove background colors from `dircolors`.
eval "$(f=$(mktemp); dircolors -p | \
    sed 's/ 4[0-9];/ 01;/; s/;4[0-9];/;01;/g; s/;4[0-9] /;01 /' > "$f"; \
    dircolors "$f"; rm "$f")"

alias ls="ls -h --color=auto --hide='ntuser*' --hide='NTUSER*'"
alias grep="grep --color=auto"
alias egrep="egrep --color=auto"
alias fgrep="fgrep --color=auto"

if [ -n "$MSYSTEM" ]; then
    [ -x /clang64/bin/rg ]  && alias rg=/clang64/bin/rg
    [ -x /clang64/bin/rga ] && alias rga=/clang64/bin/rga
fi

shopt -s histappend
shopt -s globstar
shopt -s checkwinsize

PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

COMP_CONFIGURE_HINTS=1
COMP_TAR_INTERNAL_PATHS=1

source /usr/share/bash-completion/bash_completion 2>/dev/null

export HISTSIZE=30000
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups:erasedups
export HISTIGNORE=$'[ \t]*:&:[fb]g:exit:ls' # Ignore the ls command as well
