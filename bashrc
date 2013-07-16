[[ $- == *i* ]] || return

function brc {
	. ~/.bashrc
}

function pushd {
	command pushd "${@:-"$HOME"}"
}

# WARNING: functions that call localopt will have their trace attribute automatically removed.
function localopt {
	typeset -a unsetopts setopts
	typeset opts serverlist servername=manpages

	for opts in "$@"; do
		if [[ $SHELLOPTS != *${opt}* ]]; then
			set -o "$opt"
			unsetopts+=("$opt")
		fi
	done
}

#function man {
#	if ! command man -W "$@"; then
#		return 1
#	elif [[ ! -t 0 ]]; then 
#		echo 'STDIN must be a tty.' >&2
#		return 1
#	fi
#
#
#	if [[ $- != *m* ]]; then
#		set -m
#	fi
#
#	trap 'trap RETURN; set +m' RETURN
#
#	typeset serverlist servername=manpages
#
#	# if vim --serverlist | grep -q "$servername"
#
#	typeset serverlist
#	vim --serverlist | mapfile -tc1 -C ' serverlist'
#
#	{
#		{
#			groffer --text -Tutf8 -rLL=$((${COLUMNS:-$(tput cols)}-10))n -man "$@" 2>/dev/null ||
#				kill -"$BASHPID"
#		} | sed -e 's/\x1B\[[[:digit:]]\+m//g' | vim -c 'set nomod ft=man' --servername manpages --remote /dev/fd/4 4<&0 <&3
#	} 3<&0
#}

function kvmmodprobe {
	typeset x
	echo 'loading modules:'

	{
		find "/lib/modules/$(uname -r)" -iname '*virtio*' -printf '%f\0'
		printf '%s\0' 9p # Additional modules.
	} | while IFS= read -rd '' x; do
			x=${x%.*}
			printf '%4s%s\n' '' "$x"
			modprobe -- "$x"
		done
}

function sprunge {
	curl -sF 'sprunge=<-' 'http://sprunge.us' <"${1:-/dev/stdin}"
}

function doCygwin {
	shopt -s extglob globstar lastpipe cmdhist lithist histappend checkwinsize 2>/dev/null

	# Change the window title of X terminals 
	case $TERM in
		xterm*|rxvt*|Eterm|aterm|kterm|gnome*|interix)
			PROMPT_COMMAND='printf "\E]0;%s@%s:%s\a" "$USER" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
			;;
		screen*)
			PROMPT_COMMAND='printf "\E_%s@%s:%s\E\\" "$USER" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
	esac

	if x=$(tput colors) y=$? let 'y || x >= 8' && type -P dircolors >/dev/null; then
		if [[ -f ~/.dir_colors ]]; then
			eval "$(dircolors -b ~/.dir_colors)"
		elif [[ -f /etc/DIR_COLORS ]]; then
			eval "$(dircolors -b /etc/DIR_COLORS)"
		fi

		#if [[ ${EUID:-$(id -u)} == 0 ]] ; then
			#PS1='\[\033[01;31m\]\h\[\033[01;34m\] \W \$\[\033[00m\] '
		#else
			#PS1='\[\033[01;32m\]\u@\h\[\033[01;34m\] \w \$\[\033[00m\] '
		#fi

		ls() { command ls --color=auto "$@"; }
		grep() { command grep --color=auto "$@"; }
	elif [[ ${EUID:-$(id -u)} == 0 ]]; then
		# PS1='\u@\h \W \$ '
		:
	else
		# PS1='\u@\h \w \$ '
		:
	fi
}

function doLinux {
	shopt -s extglob globstar lastpipe cmdhist lithist histappend checkwinsize 2>/dev/null

	export \
		PATH=/home/smorg/doc/projects/bash/scripts:${PATH} \
		PAGER=vimpager \
		MANPAGER=vimmanpager \
		BROWSER=chromium-browser-live
}

function main {
	unset -v PYTHONPATH
	typeset -f +t "$FUNCNAME"
	trap 'trap - RETURN; unset -f "$FUNCNAME"' RETURN
	stty -ixon -ctlecho
	shopt -u interactive_comments
	set -o vi
	set +o histexpand

	case $(uname -o) in
		Cygwin)
			doCygwin
			;;
		GNU/Linux)
			doLinux
			;;
		*)
			printf '%s\n' 'bashrc: Unknown "uname -o", assuming Linux' >&2
			doLinux
	esac

	. "$(dirname "$(readlink -snf "$BASH_SOURCE")")/functions"

	declare -g \
		PROMPT_DIRTRIM=3 \
		HISTSIZE=1000000 \
		HISTTIMEFORMAT='%c ' \
		PROMPT_COMMAND='history -a'


	if [[ $TERM == linux ]]; then
		export TERM=linux-16color
		loadkeys -
	fi <<\EOF 2>/dev/null
keycode 1 = Caps_Lock
keycode 58 = Escape
EOF

	# www-plugins/chrome-binary-plugins
	# . /etc/chromium/pepper-flash www-plugins/chrome-binary-plugins

	# [[ -f /etc/profile.d/bash-completion ]] && . /etc/profile.d/bash-completion
}

# We want to show error output only if reloading this file via the `brc' wrapper.
if [[ ${FUNCNAME[1]} == brc ]]; then
	main "$@"
else
	main "$@" >/dev/null 2>&1
fi

# vim: set fenc=utf-8 ff=unix :
