[[ $- != *i* ]] && return

set -o vi ignoreeof bgnice globstar
stty -ixon
[[ $- == *m* ]] && stty susp '^Z'

PATH="/home/smorg/doc/projects/bash/scripts:${PATH}"
MANPAGER="vimmanpager"
HTMLPAGER="chromium-browser"
PROMPT_DIRTRIM=3

TZ='US/Central'

unset LC_ALL PYTHONPATH

# LANG="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8" export LC_NUMERIC="en_US.UTF-8" export LC_TIME="en_US.UTF-8"
export LC_COLLATE="en_US.UTF-8"
export LC_MONETARY="en_US.UTF-8"
export LC_MESSAGES="en_US.UTF-8"
export LC_PAPER="en_US.UTF-8"
export LC_NAME="en_US.UTF-8"
export LC_ADDRESS="en_US.UTF-8"
export LC_TELEPHONE="en_US.UTF-8"
export LC_MEASUREMENT="en_US.UTF-8"
export LC_IDENTIFICATION="en_US.UTF-8"

umask 0027

if whence -p dircolors >/dev/null ; then
    if [[ -f ~/.dir_colors ]] ; then
        eval ${ dircolors -b ~/.dir_colors;}
    elif [[ -f /etc/DIR_COLORS ]] ; then
        eval ${ dircolors -b /etc/DIR_COLORS;}
    fi
fi

typeset -A colrs=( [Rc]="${ tput setaf 1;}" [Yc]="${ tput setaf 3;}" [Bc]="${ tput setaf 4;}" [Wc]="${ tput -S <<<$'setaf 7\nbold\n';}" [Nc]="${ tput setaf sgr;}" )

PS1="${USER:-$(whoami 2>/dev/null)}@$(uname -n 2>/dev/null) \$ "

#if [[ $(id -u) -eq 0 && $USER == 'root' ]]; then
#    PS1="${Rc}[${Nc}${USER}${Wc}${PWD}${Nc}${Rc}]${Nc}${Wc}# ${Nc}"
#    PS2="${Rc}>  ${Nc}"
#else
#    PS1=""
#fi

function ccmon {
    while :; do
        for i in /sys/kernel/mm/cleancache/*; do
            printf '%-15s %d\n' "${i##*/}:" "$(< $i)"
        done
        sleep .5
        clear
    done
}

function clk {
    typeset base=/sys/class/drm/card0/device
    case $1 in
        low|high|default)
            printf '%s\n' "temp: $(< ${base}/hwmon/hwmon0/temp1_input)C" "old profile: $(< ${base}/power_profile)"
            echo "$1" >${base}/power_profile
            echo "new profile: $(< ${base}/power_profile)";;
        *)
            echo "Usage: ${FUNCNAME[0]} [ low | high | default ]"
            printf '%s\n' "temp: $(< ${base}/hwmon/hwmon0/temp1_input)C" "current profile: $(< ${base}/power_profile)"
    esac
}

function eapi {
    nohup okular "$(equery f --filter 'doc' 'app-doc/pms:live' | grep '.pdf')" >/dev/null 2>&1 &
}

function flags {
    egrep '^(C|LD)(XX)?FLAGS' </etc/make.conf | mapfile -t out
    echo "${out[@]}"
}

function grep {
    command grep '--colour=auto' "$@"
}

function krc {
    . ~/.kshrc
}

function ls {
    command ls '--color=auto' "$@"
}

function lsfd {
    typeset ofd=${ofd:-2} target=${target:-$$}

    case ${1##+(-)} in
        u)
            shift
            ofd=$1
            shift
            ;;
        t)
            shift
            target=$1
            shift
            ;;
        h|\?|help)
            cat
            return
    esac <<EOF
USAGE: ${.sh.fun} [-h|-?|--help] [-u <fd>] [<fd1> <fd2> <fd3>...]

This is a small lsof wrapper which displays the open
file descriptors of the current BASHPID. If no FDs are given,
the default FDs to display are {0..20}. ofd can also be set in the
environment.

    -u <fd>: Use fd for output. Defaults to stderr. Overrides ofd.
EOF

    typeset IFS=, fds=(${*:-{0..20}}) fds=("${fds[*]}")
    lsof -a -p $target -d "$fds" +f g -- >&2 # >&${ofd}
}

function pwmake {
    typeset -a a=( {a..z} {A..Z} {0..9} )
    printf '%.1s' "${a[RANDOM%${#a[@]}]}"{0..15} $'\n' 
}

function rmvtp {
    rm -rf /var/tmp/portage/*
}

function sprunge {
      curl -sF 'sprunge=<-' 'http://sprunge.us' < "${1:-/dev/stdin}"
}

function trayr {
    /usr/bin/trayer --edge top \
                    --align right  \
                    --SetDockType true  \
                    --SetPartialStrut true  \
                    --expand true  \
                    --widthtype percent  \
                    --width 15  \
                    --transparent true  \
                    --tint 0x000000  \
                    --heighttype pixel  \
                    --height 12 &
}

function vimr {
    vim --servername smorg --remote "$@"
}

function weechat {
    weechat-curses "$@"
}

function whois {
    whois -H "$@"
}

# vim: fenc=utf-8 ff=unix ts=4 sts=4 sw=4 ft=sh nowrap et :
