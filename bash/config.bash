#!/bin/bash
stty ixany
stty ixoff -ixon
set -o ignoreeof

export EDITOR="emacs -nw"
export GIT_EDITOR="emacs -nw"
export GOPATH="$HOME/.go"
export KREW_ROOT="$HOME/.krew"
export HISTCONTROL=ignoredups:ignorespace
export HISTFILESIZE=-1
export HISTSIZE=-1
export LESS=R
export LS_COLORS="or=41;01:mi=41;01"
export NVM_DIR="$HOME/.nvm"
export PYTHONDONTWRITEBYTECODE=1
export PYTHONBREAKPOINT="ipdb.set_trace"
export TERM="xterm-256color"
export VISUAL=emacs

PATH="/opt/bin/:$PATH"
PATH="/opt/homebrew/bin:$PATH"
PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
PATH="/usr/local/heroku/bin:$PATH"
PATH="$GOPATH/bin:$PATH"
PATH="$KREW_ROOT/bin:$PATH"
PATH="$HOME/.cargo/bin:$PATH"
PATH="$HOME/Library/Python/3.9/bin:$PATH"
PATH="$HOME/.local/bin:$PATH"

CONTEXT_COLOR="$(context-color -p)"
FAIL_COLOR="\\[$(tput setaf 1)\\]"

echo-and-run() {
    echo -e "$@"
    eval "$@"
}

source-if-exists() {
    if [[ -f "$1" ]]
    then
        # shellcheck source=/dev/null
        source "$1"
    fi
}

set-venv() {
    if [[ -d ".venv" ]] && [ ! "$AUTO_SOURCED_VENV" ];
    then
        echo-and-run source .venv/bin/activate
        AUTO_SOURCED_VENV="$(pwd)"
        export AUTO_SOURCED_VENV
    elif [ "$AUTO_SOURCED_VENV" ] \
             && { [[ ! "$(pwd)" =~ $AUTO_SOURCED_VENV ]] \
                      || [[ ! -d "$AUTO_SOURCED_VENV/.venv" ]]; }
    then
        echo-and-run deactivate 2> /dev/null
        unset AUTO_SOURCED_VENV
    fi
}

set-prompt() {
    # shellcheck disable=SC2181
    if [[ "$?" != 0 ]]
    then
        color="$FAIL_COLOR"
    else
        color="$CONTEXT_COLOR"
    fi

    user="\\[\\e[37;1m\\]\\u"
    at="$color@"
    host="\\[\\e[37;1m\\]\\h"
    jobs="\\[\\e[0m\\]$color:\\j"
    path="\\[\\e[37;1m\\]$color\\w"

    set-venv
    if [[ "$VIRTUAL_ENV" ]]
    then
        venv="\\[\\e[38;5;242m\\]◌$(basename "$VIRTUAL_ENV") "
    else
        venv=""
    fi

    if [[ -n "$(type -t __git_ps1)" ]]
    then
        git="\\[\\e[38;5;242m\\]$(__git_ps1 '⎇ %s ')"
    else
        git=""
    fi

    PS1="$user$at$host $jobs $path $venv$git\\[\\e[0m\\]"
}

load-env() {
    set -o allexport
    source-if-exists .env
    set +o allexport
}

set-title() {
    echo -ne "\033]0;$(whoami)@$(hostname) :$(jobs | wc -l) $(dirs)\007"
}

reload-history() {
    history -a
    history -r
}

PROMPT_COMMAND="set-prompt; load-env; set-title; reload-history"

shopt -s autocd
shopt -s checkwinsize
shopt -s cmdhist
shopt -s extglob
shopt -s globstar
shopt -s histappend

alias activate='. .venv/bin/activate 2>/dev/null || . .env/bin/activate 2>/dev/null'
alias clean='rm -vf $(find . -name "*~" -or -name "*.pyc" -or -name "*.pyo" -or -name "#*#" \
             -or -name "*.class" -or -name "*_flymake.py" 2> /dev/null)'
alias dog='pygmentize -g'
alias emacs-clean='rm -vf `find ~/.emacs.d/ | grep \.elc`'
alias emacs-re="emacs-clean && emacs-compile"
alias grep='grep --color=auto -I --line-buffered'
alias killmosh='pgrep mosh-server | grep -v $(ps -o ppid --no-headers $$) | xargs kill &> /dev/null || true'
alias lines='cat `find . -type f` | wc -l'
alias loc='find . -not -path "*.git*" -not -path "*.venv*" -type f | xargs wc -l'
alias ls='ls --color=auto -F'
alias modprobe='modprobe --first-time'
alias mv='mv -i'
alias nautilus='nautilus --no-desktop'
alias pytest='pytest --pdbcls=IPython.terminal.debugger:TerminalPdb'
alias randpass='apg -MsNCL -m10'
alias reactivate='deactivate; activate'
alias reload='source ~/.bashrc'
alias sudo='sudo -E '

cd() {
    builtin cd "$@" && echo-and-run ls
}

diff() {
    colordiff -Nu "$@" | diff-highlight
}

hl() {
    # shellcheck disable=SC2145
    grep -E "$@|"
}

kt() {
    command kt "$@" -z 2,8,10,16,17,18,19,20,21,22,23,24,25,26,27
}

csv_pp() {
    if [[ "$2" ]]
    then
        DELIMITER="$2"
    else
        DELIMITER=","
    fi
    column -s"$DELIMITER" -t < "$1" | less -#2 -N -S
}

emacs() {
    if [[ "$*" == *"--daemon"* || "$*" == *"--help"* || "$*" == *"--version"* || "$*" == *"--batch"* ]]
    then
        command emacs -nw "$@"
    else
        emacsclient --tty -c -nw -a= --socket-name=$(whoami) "$@"
    fi
}

source-if-exists ~/.bash_aliases
source-if-exists ~/.git-prompt.sh
source-if-exists ~/.kctx.bash
source-if-exists ~/.kns.bash
source-if-exists ~/.kt.bash
source-if-exists ~/.nvm/nvm.sh
source-if-exists /usr/share/bash-completion/bash_completion
source-if-exists /opt/homebrew/etc/profile.d/bash_completion.sh

complete -C /usr/bin/terraform terraform
complete -C 'aws_completer' aws
source <(qovery completion bash 2> /dev/null)
source <(pulumi gen-completion bash 2> /dev/null)
