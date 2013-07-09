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

function main {
	unset -v PYTHONPATH
	typeset -f +t "$FUNCNAME"
	trap 'trap - RETURN; unset -f "$FUNCNAME"' RETURN
	stty -ixon -ctlecho
	shopt -s extglob globstar lastpipe cmdhist lithist histappend checkwinsize
	shopt -u interactive_comments
	set -o vi
	set +o histexpand

	. "$(dirname "$(readlink -snf "$BASH_SOURCE")")/functions"

	declare -g \
		PROMPT_DIRTRIM=3 \
		HISTSIZE=1000000 \
		HISTTIMEFORMAT='%c ' \
		PROMPT_COMMAND='history -a'

	export \
		PATH=/home/smorg/doc/projects/bash/scripts:${PATH} \
		PAGER=vimpager \
		MANPAGER=vimmanpager \
		BROWSER=chromium-browser-live

	if [[ $TERM == linux ]]; then
		export TERM=linux-16color
		loadkeys - <<\EOF 2>/dev/null
keycode 1 = Caps_Lock
keycode 58 = Escape
EOF
	fi

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
