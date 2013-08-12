[[ $- == *i* ]] || return

# WARNING: functions that call localopt will have their trace attribute automatically removed.
#function localopt {
#	typeset -a unsetopts setopts
#	typeset opts serverlist servername=manpages
#
#	for opts in "$@"; do
#		if [[ $SHELLOPTS != *${opt}* ]]; then
#			set -o "$opt"
#			unsetopts+=("$opt")
#		fi
#	done
#}

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

function brc { . ~/.bashrc; }
function pushd { command pushd "${@:-"$HOME"}"; }
function sprunge { curl -sF 'sprunge=<-' 'http://sprunge.us' <"${1:-/dev/stdin}"; }
function weechat { weechat-curses; }
function whois { command whois -H "$@"; }

function conditionalDefine {
	shopt -s extglob globstar lastpipe cmdhist lithist histappend checkwinsize 2>/dev/null

	case $(uname -o) in
		Cygwin)
			typeset curOS=Cygwin
			;;
		GNU/Linux)
			typeset curOS=Linux
			;;
		*)
			printf '%s\n' 'bashrc: Unknown "uname -o", assuming Linux' >&2
			typeset curOS=Linux
	esac

	case $curOS in
		Cygwin)
			# Change the window title of X terminals 
			case $TERM in
				xterm*|rxvt*|Eterm|aterm|kterm|gnome*|interix)
					PROMPT_COMMAND='printf "\E]0;%s@%s:%s\a" "$USER" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
					;;
				screen*)
					PROMPT_COMMAND='printf "\E_%s@%s:%s\E\\" "$USER" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
			esac

			PROMPT_DIRTRIM=3
			HISTSIZE=1000000
			HISTTIMEFORMAT='%c '
			PROMPT_COMMAND='history -a'

			export \
				PAGER=less \
				MANPAGER=less

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

			function autossh-wrapper {
				while :; do
					autossh -M 1234 -nNTR 3333:localhost:4114 smorg@ormaaj.org
					sleep 30
				done
			}

			function cygServerAdmin {
				while :; do
					if ! net localgroup Administrators | grep -q cyg_server; then
						net localgroup Administrators cyg_server /add
						cygrunsrv -E sshd
						sleep 1
						cygrunsrv -S sshd
					fi
					sleep 20
				done
			}
			;;

		Linux)
			shopt -s extglob globstar lastpipe cmdhist lithist histappend checkwinsize 2>/dev/null

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
	esac

	# $(</dev/fd/*) broken on Cygwin
	function _function {
		typeset IFS=$' \t\n'
		[[ -t 0 || -z ${1:+_} ]] && return 1
		command eval function "$1" $'{\n' "$(cat)" $'\n}'
	}
	
	[[ $curOS == "Linux" ]]
	_function vimr <<'CYGWIN' 3<&0 <<'LINUX' <&$((3 * $?))
typeset -a serverList vimCmd=(gvim -v)
mapfile -t serverList < <("${vimCmd[@]}" --serverlist)
"${vimCmd[@]}" --servername "${serverList[0]:-ormaaj}" ${serverList[0]:+--remote} "$@"
CYGWIN
typeset -a serverList vimCmd=(vim)
mapfile -t serverList < <("${vimCmd[@]}" --serverlist)
"${vimCmd[@]}" --servername "${serverList[0]:-ormaaj}" ${serverList[0]:+--remote} "$@"
LINUX

	[[ $curOS == "Linux" ]]
	_function vimrx <<'CYGWIN' 3<&0 <<'LINUX' <&$((3 * $?))
typeset -a fpath
typeset x
while IFS= read -r x; do
	fpath=$(cygpath -u "$x") && [[ ( ! -e $fpath ) && $fpath =~ ^\"(.*)\"$ ]] && fpath+=("${BASH_REMATCH[1]}")
done < <(xclip -o)
vimr "${fpath[@]}"
CYGWIN
vimr "$(xclip -o)"
LINUX

	unset -f _function
}

function main {
	unset -v PYTHONPATH
	typeset -f +t "$FUNCNAME"
	trap 'trap - RETURN; unset -f "$FUNCNAME"' RETURN
	stty -ixon -ctlecho
	shopt -u interactive_comments
	set -o vi
	set +o histexpand

	export XMLLINT_INDENT='    '
	conditionalDefine

	. "$(dirname "$(readlink -snf "$BASH_SOURCE")")/functions"


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
