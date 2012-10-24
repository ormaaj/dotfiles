[[ $- != *i* ]] && return
stty -ixon

export PATH="/home/smorg/doc/projects/bash/scripts:$PATH" MANPAGER=vimmanpager HTMLPAGER=chromium-browser

unset LC_ALL PYTHONPATH
umask 0027

if whence -p dircolors; then
    if [[ -f ~/.dir_colors ]]; then
        eval "$(dircolors -b ~/.dir_colors)"
    elif [[ -f /etc/DIR_COLORS ]]; then
        eval "$(dircolors -b /etc/DIR_COLORS)"
    fi
fi >/dev/null 

set -o vi ignoreeof bgnice globstar

typeset -T Prompt_t=(
    integer EUID

    typeset -SA colrs=(
        [R]=$(tput setaf 1)
        [Y]=$(tput setaf 3)
        [B]=$(tput setaf 4)
        [W]=$(tput -S <<<$'setaf 7\nbold\n')
        [N]=$(tput setaf sgr)
    )

    function create {
        if (($(id -u))); then
            nameref _.userClr=
        fi
    }

    function EUID.get {
        .sh.value=$(id -u)
    }

    function get {
        case ${.sh.name} in
            PS1)
                .sh.value=
        esac
    }
)

{ PS1="${USER:-${ id -un;}}@${ uname -n;} \$ "; } 2>/dev/null

#if [[ $(id -u) -eq 0 && $USER == 'root' ]]; then
#    PS1="${Rc}[${Nc}${USER}${Wc}${PWD}${Nc}${Rc}]${Nc}${Wc}# ${Nc}"
#    PS2="${Rc}>  ${Nc}"
#else
#    PS1=""
#fi

# Debugging function for colored display of argv.

function args {
    if [[ -t ${ofd:-2} ]]; then
        typeset -A clr=( [green]="${ tput setaf 2;}" [sgr0]="${ tput sgr0;}" )
    else
        typeset clr
    fi

    printf -- "${clr[green]}<${clr[sgr0]}%s${clr[green]}>${clr[sgr0]} " "$@"
    echo
} >&"${ofd:-2}"

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
            printf '%s\n' "temp: $(<${base}/hwmon/hwmon0/temp1_input)C" "old profile: $(< ${base}/power_profile)"
            print "$1" >${base}/power_profile
            print "new profile: $(<${base}/power_profile)";;
        *)
            print "Usage: ${FUNCNAME[0]} [ low | high | default ]"
            printf '%s\n' "temp: $(<${base}/hwmon/hwmon0/temp1_input)C" "current profile: $(< ${base}/power_profile)"
    esac
}

function eapi {
    nohup okular "$(equery f --filter 'doc' 'app-doc/pms:live' | grep '.pdf')" >/dev/null 2>&1 &
}

#function flags {
#    egrep '^(C|LD)(XX)?FLAGS' </etc/make.conf | mapfile -t out
#    echo "${out[@]}"
#}

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
    lsof -a -p $target -d "$fds" +f g -- >&${ofd}
}

function pwmake {
    typeset -a a=({a..z} {A..Z} {0..9})
    printf '%.1s' "${a[RANDOM%${#a[@]}]}"{0..15} $'\n' 
}

function rmvtp {
    rm -rf /var/tmp/portage/*
}

function sprunge {
      curl -sF 'sprunge=<-' 'http://sprunge.us' <"${1:-/dev/stdin}"
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
    command whois -H "$@"
}

# vim: fenc=utf-8 ff=unix ts=4 sts=4 sw=4 ft=sh nowrap et :
