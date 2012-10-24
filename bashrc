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

    if (( $# )); then
        printf -- "${clr[green]}<${clr[sgr0]}%s${clr[green]}>${clr[sgr0]} " "$@"
        echo
    else
        echo 'no args.'
    fi

} >&"${ofd:-2}"

brc() {
    . ~/.bashrc
}

# Direct recursion depth.
# Search up the stack for the first non-FUNCNAME[1] and count how deep we are.
# Result goes to stdout, or is optionally assigned to the given variable name.
callDepth() {
    # Unset all locals, then "Return" the output or assign to the given variable.
    if [[ $FUNCNAME == ${FUNCNAME[1]} ]]; then
        unset -v n fnames
        printf "$@"
        return
    fi

    # Strip "main" off the end of FUNCNAME[@] if current function is named "main" and
    # Bash added an extra "main" for non-interactive scripts.
    if [[ main == !(!("${FUNCNAME[1]}")|!("${FUNCNAME[-1]}")) && $- != *i* ]]; then
        local -a 'fnames=("${FUNCNAME[@]:1:${#FUNCNAME[@]}-2}")'
    else
        local -a 'fnames=("${FUNCNAME[@]:1}")'
    fi

    local n
    # If this is the global scope, then zero.
    (( ${#fnames[@]} )) || callDepth ${1:+-v "$1"} 0

    # Otherwise, count until the first fname.
    while [[ $fnames == ${fnames[++n]} ]]; do
        :
    done

    callDepth ${1:+-v "$1"} -- "$n"
}

# Formatted cleancache stats
ccmon() {
    local interval="${1:-.5}"

    while :; do
        for i in /sys/kernel/mm/cleancache/*; do
            printf '%-15s %d\n' "${i##*/}:" "$(<"$i")"
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

eResolveAtom() {
    local my_overlay=$(portageq get_repo_path / custom)

    case $(
            trap 'printf %s "$?"' EXIT
            [[ ${1+_} ]] || exit 4
            NOFOUND_STATUS=2 MOREFOUND_STATUS=3 eix --only-names -e -- "$1" >/dev/stdin
        )
        in
        0) if [[ ! $(</dev/stdin) =~ (.*)/(.*) ]]; then
               echo 'Error parsing atom.'
               return 6
           fi
           ;;
        1) echo 'eix returned status 1'
           return 1
           ;;
        2) echo "No packages matching $1"
           return 2
           ;;
        3|4) printf '%s' 'Must specify a unique package atom.'
           ;;&
        3) echo "${1} matches:"
           cat
           return 3
           ;;
        4) echo
           return 4
           ;;
        *) echo 'eix returned unknown status > 4'
           return 5
    esac <<<'' >&2

    eval "${2}"'=( "${BASH_REMATCH[@]}" )'
}

etest() {
    local INFD savefd
    export INFD
    {
        ebuild --skip-manifest "$(portageq get_repo_path / custom)"/gentoo-debug/p/p-0.ebuild "${@:1:$#-1}"
    } {savefd}<&0 <<<"${!#}" {INFD}<&0 <&"$savefd"-
    cat "$(portageq envvar PORTAGE_TMPDIR)"/portage/
}

flags() (
    grep -E '^(C|LD)(XX)?FLAGS' </etc/make.conf | mapfile -t out
    echo "${out[@]}"
)

info() {
    command info --vi-keys
}

#inArray() {
#        set -- "$1" "${2}[@]"
#        local x
#        for x in "${!2}"; do
#            [[ $1 == "$1" ]] && return
#        done
#    else
#        x=$1 "$FUNCNAME" "${!2}"
#    fi
#}

ixio() {
    local -a 'args=( 
    local n x

    for x; do
        args+=([++n]='-F' "f:$((++n))=<")


    curl -F "f:1=<-' 'http://ix.io' <"${1:-/dev/stdin}"
}

# Find the last modified file selected from a glob.
# Usage: latest <glob> <varname>
# Takes an optional glob and optional varname.
# glob defaults to '*'. If varname is set, assign to varname,
# else output to stdout.
function latest {
    if [[ $FUNCNAME == ${FUNCNAME[1]} ]]; then
        unset -v x latest files
        printf -v "$@"
    elif (($# > 2)); then
        printf '%s\n' "Usage: $FUNCNAME <glob> <varname>" 'Error: Takes at most 2 arguments. Glob defaults to *'
        return 1
    else
        if ! shopt -q nullglob; then
            typeset -f +t "$FUNCNAME"
            trap 'shopt -u nullglob; trap - RETURN' RETURN
            shopt -s nullglob
        fi

        IFS= typeset -a 'files=(${1:-*})'
        typeset latest x

        for x in "${files[@]}"; do
            [[ -d $x || $x -ot $latest ]] || latest=$x
        done

        ${2:+"$FUNCNAME"} "${2:-printf}" -- %s "$latest"
    fi
}

# lsof wrapper
lsfd() {
    local -A opts=( [u]=ofd [t]=target )
    local ofd=${ofd:-2} target=${target:-$BASHPID}

    while [[ $1 == -* ]]; do
        if [[ $1 != -@(h|\?|help) && $2 != +([[:digit:]]) ]]; then
            cat
            return 1
        fi
        case ${1##+(-)} in
            u)
                ofd=$2
                shift 2
                ;;
            t)
                target=$2
                shift 2
                ;;
            h|\?|help)
                cat
                return 0
        esac
    done <<EOF
USAGE: ${FUNCNAME} [-h|-?|--help] [-u <fd>] [ -t <PID> ] [<fd1> <fd2> <fd3>...]

This is a small lsof wrapper which displays the open file descriptors of the
current BASHPID. If no FDs are given, the default FDs to display are those open
by the current process. ofd can also be set in the environment.

    -u <fd>: Use fd for output. Defaults to stderr. Overrides ofd set in the environment.
    -t <PID>: Use PID instead of BASHPID. Overrides "target" set in the environment.
EOF

    IFS=, local -a fds=\("${*:-/proc/"${target:-self}"/fd/*}"\) 'fds=("${fds[*]##*/}")'
    lsof -a -p $target -d "$fds" +f g -- >&${ofd} # >&2
}

# Fix for broken applications (all KDE apps) which cannot read either stdin or pipes. Example:
# curl -s "example.com/foo.c" | pipewrap kompare /dev/stdin ~/foo.c
pipewrap() {
    "$@" <<<"$(</dev/stdin)"
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

togglePolipo()
    if (( EUID )); then
        echo 'Must be root'
        return 1
    else
        ed -s /etc/polipo/config
        rc-service polipo restart
    fi <<\EOF
g/#\?socksP/s/^/#/\
s/^##//\
p
w
EOF

pushd() {
      builtin pushd "${@:-$HOME}"
}

pushPromptCommand() {
    eval "$PROMPT_COMMAND"
    case $TERM in
        xterm*|rxvt*|Eterm|aterm|kterm|gnome*|interix)
            PROMPT_COMMAND='printf "\E]0;%s@%s:%s\a" "$USER" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
            ;;
        screen*)
            PROMPT_COMMAND='printf "\E_%s@%s:%s\E\\" "$USER" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
            ;;
    esac
}

remapEsc() {
    xmodmap -
    xset r rate 175 65
} <<"EOF"
remove Lock = Caps_Lock
keysym Escape = Caps_Lock
keysym Caps_Lock = Escape
add Lock = Caps_Lock
EOF

# Print or assign a random alphanumeric string of a given length.
# rndstr len [ var ]
rndstr()
    if [[ $FUNCNAME == "${FUNCNAME[1]}" ]]; then
        unset -v a b
        printf "$@"
    elif [[ $1 != +([[:digit:]]) ]]; then
        return 1
    elif (( ! $1 )); then
        return
    else
        local -a a=({a..z} {A..Z} {0..9}) 'b=("${a[RANDOM%'"${#a[@]}"']"{1..'"$1"'}"}")'
        ${2:+"$FUNCNAME" -v} "${2:-printf}" -- %s "${b[@]}"
    fi

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
    --height 12
    )

    trayer "${opts[@]}"
}

# Unset the shell variable of the given args
# in the next-outermost scope.
unset2() {
    unset -v -- "$@"
}

unspecialize() {
    ${1:+command eval ''}
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

zip_longest() {
    if [[ $1 == -v ]]; then :; fi  


    : "${_[0]"{0..9}"+"{"x","x"}"}" # "
}

main() {
    shopt -s extglob globstar lastpipe cmdhist lithist histappend checkwinsize
    shopt -u interactive_comments
    set -o vi
    set +o histexpand
    stty -ixon -ctlecho
    unset -v PYTHONPATH

    declare -g PROMPT_DIRTRIM=3 \
        HISTSIZE=1000000 \
        HISTTIMEFORMAT='%c ' \
        PROMPT_COMMAND='history -a'

    declare -gx PATH=/home/smorg/doc/projects/bash/scripts:${PATH} \
        MANPAGER=vimmanpager \
        BROWSER=chromium-browser-live

    if [[ $TERM == linux ]]; then
        export TERM=linux-16color
        loadkeys - 2>/dev/null
    fi <<"EOF"
keycode 1 = Caps_Lock
keycode 58 = Escape
EOF

    # [[ -f /etc/profile.d/bash-completion ]] && . /etc/profile.d/bash-completion
}

main

# vim: fenc=utf-8 ff=unix ts=4 sts=4 sw=4 ft=sh nowrap et :
