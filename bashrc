# These functions assume the very latest Bash. 

[[ $- != *i* ]] && return
shopt -s extglob  

# Debugging function for colored display of argv.
args() {
    if [[ $- == *x* ]]; then
        set +x
        trap 'set -x' RETURN
    fi
    
    if [[ -t ${ofd:-2} ]]; then
        local -A 'clr=( [green]="$(tput setaf 2)" [sgr0]="$(tput sgr0)" )'
    else
        local clr
    fi

    printf -- "${clr[green]}<${clr[sgr0]}%s${clr[green]}>${clr[sgr0]} " "$@"
    echo

} >&"${ofd:-2}"

brc() {
    . ~/.bashrc
}

# Direct recursion depth.
# Search up the stack for the first non-FUNCNAME[1] and count how deep we are.
callDepth() {
    # Strip "main" off the end of FUNCNAME[@] if current function is named "main" and
    # Bash added an extra "main" for non-interactive scripts.
    if [[ main == !(!("${FUNCNAME[1]}")|!("${FUNCNAME[-1]}")) && $- != *i* ]]; then
        local -a 'fnames=("${FUNCNAME[@]:1:${#FUNCNAME[@]}-2}")'
    else
        local -a 'fnames=("${FUNCNAME[@]:1}")'
    fi

    if (( ! ${#fnames[@]} )); then 
        printf 0 
        return
    fi

    local n
    while [[ $fnames == ${fnames[++n]} ]]; do
        :
    done

    printf -- $n
}

# Formatted cleancache stats
ccmon() {
    local interval="${1:-.5}"

    while :; do
        for i in /sys/kernel/mm/cleancache/*; do
            printf '%-15s %d\n' "${i##*/}:" "$(< $i)"
        done
        sleep "$interval"
        clear
    done
}

# Set radeon power management
clk() {
    local base=/sys/class/drm/card0/device
    case $1 in
        low|high|default)
            printf '%s\n' "temp: $(<${base}/hwmon/hwmon0/temp1_input)C" "old profile: $(<${base}/power_profile)"
            echo "$1" >${base}/power_profile
            echo "new profile: $(<${base}/power_profile)"
            ;;
        *)
            echo "Usage: $FUNCNAME [ low | high | default ]"
            printf '%s\n' "temp: $(<${base}/hwmon/hwmon0/temp1_input)C" "current profile: $(<${base}/power_profile)"
    esac
}

# Open EAPI pdf
eapi() {
    nohup okular "$(equery f --filter 'doc' 'app-doc/pms:live' | grep '.pdf$')" &
} >/dev/null 2>&1

# List eix overlay numbers.
eolist() {
    OVERLAYS_LIST=all PRINT_COUNT_ALWAYS=never eix -!
}

# Broken
# Manage local overlays
ecopy() {
    local my_overlay=/home/smorg/doc/custom

    case $(NOFOUND_STATUS=2 MOREFOUND_STATUS=3 eix --only-names -- "$1" >&3; echo "$?") in
        0) if [[ $(< /dev/stdin) =~ (.*)/(.*) ]]; then
               echo 'Error parsing atom? WTF?'
               return 5
           fi
           ;;
        1) echo 'eix returned status 1'
           return 1
           ;;
        2) echo "No packages matching ${1}"
           return 2
           ;;
        3) printf '%s "%s" %s\n' 'Must specify a unique package atom.' "${1}" 'matches:'
           cat
           return 3
           ;;
        *) echo 'eix returned unknown status > 3'
           return 4
           ;;
    esac <<<'' 3>/dev/stdin

    echo "${BASH_REMATCH[@]}"
}

flags() (
    egrep '^(C|LD)(XX)?FLAGS' </etc/make.conf | mapfile -t out
    echo "${out[@]}"
)

# Find the last modified file selected from a glob.
# Usage: latest <glob> <varname>
# Takes an optional glob and optional varname.
# glob defaults to '*'. If varname is set, assign to varname,
# else output to stdout.
latest() {
    # Bending over backwards to not conflict with local names.
    if (($(callDepth) > 1)); then
        unset -v x latest files
        printf ${2:+'-v' "$2"} '%s' "$1"
        return
    fi

    if (($# > 2)); then
        echo $'Usage: latest <glob> <varname>\nError: Takes at most 2 arguments.'
        return 1
    fi >&2

    if ! shopt -q nullglob; then
        trap 'shopt -u nullglob' RETURN
        shopt -s nullglob
    fi

    local -a 'files=(${1-*})'
    local x latest

    for x in "${!files[@]}"; do
        [[ ${files[x]} -nt ${files[latest]} ]] && latest=$x
    done

    latest "${files[latest]}" ${2+"$2"}
}

# lsof wrapper
lsfd() {
    local ofd=${ofd:-2} target=${target:-$BASHPID}

    while [[ $1 == -* ]]; do
        if [[ -z $2 || $2 == *[![:digit:]]* ]]; then
            cat
            return 1
        fi
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
        esac
    done <<EOF
USAGE: ${FUNCNAME} [-h|-?|--help] [-u <fd>] [ -t <PID> ] [<fd1> <fd2> <fd3>...]

This is a small lsof wrapper which displays the open
file descriptors of the current BASHPID. If no FDs are given,
the default FDs to display are {0..20}. ofd can also be set in the
environment.

    -u <fd>: Use fd for output. Defaults to stderr. Overrides ofd set in the environment.
    -t <PID>: Use PID instead of BASHPID. Overrides "target" set in the environment.
EOF

    IFS=, local -a 'fds=('"${*:-{0..20\}}"')' 'fds=("${fds[*]}")'
    lsof -a -p $target -d "$fds" +f g -- >&${ofd} # >&2
}

# Broken
xman() {
    if [[ ${FUNCNAME[1]} != $FUNCNAME ]]; then
        local curPID=$BASHPID
        { man <({ MANPAGER=cat command man "$@"; echo "$?" >/dev/stdin; } | sed -e 's/\x1B\[[[:digit:]]\+m//g' | col -bx); } 3<&0 <<<''
    elif (( ! err = $(< /dev/stdin) )); then
        vim -c 'set ft=man' "$1" <&3 >&2
    else
        echo "man returned ${err}" >&2
        return 1
    fi
}

pushd() {
      builtin pushd "${@:-$HOME}"
}

# Print a random alphanumeric string of a given length.
rndstr() {
    [[ $1 == +([[:digit:]]) ]] || return 1
    (( $1 )) || return
    local -a 'a=( {a..z} {A..Z} {0..9} )' \
             'b=( "${a[RANDOM%${#a[@]}]"{1..'"$1"'}"}" )'
    printf '%s' "${b[@]}"
}

rmvtp() {
    rm -rf /var/tmp/portage/*
}

sprunge() {
    curl -sF 'sprunge=<-' 'http://sprunge.us' <"${1:-/dev/stdin}"
}

trayr() {
    local -a opts=(
        --edge top
        --align right
        --SetDockType true
        --SetPartialStrut true
        --expand true
        --widthtype percent
        --width 15
        --transparent true
        --tint 0x000000
        --heighttype pixel
        --height
    )

    nohup trayer "${opts[@]}"
}

# Unset the shell variable of the given args
# in the next-outermost scope.
unset2() {
    unset -v -- "$@"
}

vimr() {
    vim --servername ormaaj --remote "$@"
}

weechat() {
    weechat-curses
}

whois() {
    command whois -H "$@"
}

main() {
    shopt -s extglob globstar lastpipe
    set -o vi
    set +o histexpand
    stty -ixon -ctlecho
    unset PYTHONPATH
    declare -g PROMPT_DIRTRIM=3
    declare -gx PATH MANPAGER BROWSER 
    PATH=/home/smorg/doc/projects/bash/scripts:${PATH}
    MANPAGER=vimmanpager
    BROWSER=chromium-browser-live
    [[ -f /etc/profile.d/bash-completion ]] && . /etc/profile.d/bash-completion
}

main

# vim: fenc=utf-8 ff=unix ts=4 sts=4 sw=4 ft=sh nowrap et :
