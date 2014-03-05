[[ $- == *i* ]] || return

function onReturn {
	trap 'trap "trap - RETURN; eval $(printf %q "$1")" RETURN' RETURN
}

#function localopt {
	#typeset -a setopts
	#typeset x
	#IFS=: read -ra setopts <<<"$BASHOPTS"

	#for x in "${setopts[@]}"; do
		#if [[ $BASHOPTS != *${opt}* ]]; then
			#set -o "$opt"
			#unsetopts+=("$opt")
		#fi
	#done
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

# This file sets up the interactive environment and functions that are strictly for interactive use.

function brc { . ~/.bashrc; }
function pushd { command pushd "${@:-"$HOME"}"; }
function sprunge { curl -sF 'sprunge=<-' 'http://sprunge.us' <"${1:-/dev/stdin}"; }
function weechat { weechat-curses; }
function whois { command whois -H "$@"; }

function rmvtp {
	shopt -s nullglob
	rm -rf -- /var/tmp/portage/*
	shopt -u nullglob
}

function conditionalDefine {
	shopt -s extglob globstar lastpipe cmdhist histappend checkwinsize 2>/dev/null

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
				LESS=-r

			# Setup dircolors for Cygwin. This occurs in the global /etc/bash/bashrc under Gentoo.
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

			if [[ ! $DISPLAY ]]; then
				startxwin
				export DISPLAY=:0
			fi

			# xclip not available on 64-bit Cygwin. (And I rely upon it heavily).
			if [[ $HOSTTYPE == 'x86_64' ]]; then
				function xclip {
					case $1 in
						-o) python -c 'import gtk; print(gtk.Clipboard(gtk.gdk.display_get_default(), "CLIPBOARD").wait_for_text())'
					esac
				}
			fi

			function autossh-wrapper {
				while :; do
					autossh -M 1234 -nNTR 3333:localhost:4114 -R 3390:localhost:3389 smorg@ormaaj.org
					sleep 30
				done
			}

			function cygServerAdmin {
				while :; do
					if ! net localgroup Administrators | grep -q cyg_server; then
						net localgroup Administrators cyg_server /add
						# cygrunsrv -E sshd
						# sleep 1
						# cygrunsrv -S sshd
					fi
					sleep 10
				done
			}

			# Cygwin's plain vim built without X11 support, so run gvim nongraphically.
			function vim { gvim -v "$@"; };

			# Programmable completion (Cygwin).
			# [[ -f /etc/bash_completion ]] && . /etc/bash_completion
			;;
		Linux)
			shopt -s extglob globstar lastpipe cmdhist histappend checkwinsize 2>/dev/null

			# Programmable completion (Gentoo).
			# [[ -f /etc/profile.d/bash-completion ]] && . /etc/profile.d/bash-completion

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

			# Load kvm-related modules
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

			# rdesktop wrapper for common presets.
			function myrdp {
				rm -rf ~/.rdesktop
				case $1 in
					work)
						rdesktop -EKPzg 1920x1200 -x 0x8F -a 32 -u DWDouglas -d Orbits.net -n Unknown localhost:3390
						;;
					kvm)
						rdesktop -EKg 1920x1200 -x 0x80 -a 24 -u Administrator 192.168.1.3
						;;
					*)
						return 1
				esac
			}
	esac

	# Common functions constructed with conditional runtime behavior are below.

	# Hack function defs. Function code is read from stdin.
	# Note $(</dev/fd/*) is broken on Cygwin. Using cat instead.
	function _function {
		typeset IFS=$' \t\n'
		[[ -t 0 || -z ${1:+_} ]] && return 1
		command eval function "$1" $'{\n' "$(cat)" $'\n}'
	}
	
	[[ $curOS == "Linux" ]]
	_function vimr <<-'CYGWIN' 3<&0 <<-'LINUX' <&$((3 * $?))
		typeset -a serverList vimCmd=(gvim -v)
		mapfile -t serverList < <("${vimCmd[@]}" --serverlist)
		"${vimCmd[@]}" --servername "${serverList[0]:-ormaaj}" ${serverList[0]:+--remote} "$@"
CYGWIN
		typeset -a serverList vimCmd=(vim)
		mapfile -t serverList < <("${vimCmd[@]}" --serverlist)
		"${vimCmd[@]}" --servername "${serverList[0]:-ormaaj}" ${serverList[0]:+--remote} "$@"
LINUX

	# Windows Explorer's "copy as path" feature outputs a newline-delimited list of
	# quoted paths, with no trailing newline. This is ok since NTFS filenames can't
	# contain newlines or quotes. If we're on Cygwin, then build an array while
	# stripping quotes from pre-quoted paths only, and handle the sometimes missing
	# newline by copying to a herestring. (mapfile looks broken in 10 different
	# ways on Cygwin)
	[[ $curOS == "Linux" ]]
	_function vimrx <<-'CYGWIN' 3<&0 <<-'LINUX' <&$((3 * $?))
		typeset -a fpath
		typeset x

		while IFS= read -r x; do
			[[ ( ! -e $x ) && $x =~ ^\"(.*)\"$ ]] && x=${BASH_REMATCH[1]}
			[[ $x ]] && fpath+=("$(cygpath -u "$x")")
		done <<<"$(xclip -o)"

		if (( ${#fpath[@]} )); then
			vimr "${fpath[@]}"
		else
			echo 'No paths' >&2
			return 1
		fi
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

	# Make the xmllint formatter use 4-space indents.
	export XMLLINT_INDENT='    '

	# Access remotely checked-out files over passwordless ssh for CVS
	COMP_CVS_REMOTE=1

	# Avoid stripping description in --option=description of './configure --help'
	COMP_CONFIGURE_HINTS=1

	# Define to avoid flattening internal contents of tar files
	COMP_TAR_INTERNAL_PATHS=1


	# Do platform-specific setup
	conditionalDefine

	# Source the general-purpose function library.
	. "$(dirname "$(readlink -snf "$BASH_SOURCE")")/functions"

	# If this is a real linux VT then allow 16 colors (default is 8) and swap caps-lock / escape keys
	if [[ $TERM == linux ]]; then
		export TERM=linux-16color
		loadkeys -
	fi <<\EOF 2>/dev/null
keycode 1 = Caps_Lock
keycode 58 = Escape
EOF
}

# We want to show error output only if reloading this file via the `brc' wrapper.
if [[ ${FUNCNAME[1]} == brc ]]; then
	main "$@"
else
	main "$@" >/dev/null 2>&1
fi

# vim: set fenc=utf-8 ff=unix :
