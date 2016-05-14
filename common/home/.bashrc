#!/bin/bash
#set -x
unalias -a

	### Universal aliases and options that affect the parser must go first. ###
shopt -s extglob lastpipe expand_aliases
if [[ $(type -t ksh) == file ]]; then
	ksh -c alias | {
		while read -r; do
			[[ $(type -t "${REPLY%%=*}") == builtin ]] || eval alias "$REPLY"
		done
	}
else
	alias \
		nameref='nameref' \
		integer='typeset -i' \
		command='command ' \
		nohup='nohup '
fi

alias command='command '

# Functions used for internal setup that shouldn't be callable after this file is sourced.
function mainBashrcFuncs {
	# True if all args are valid names
	function isValidNames {
		${1:+\:} return 1
		typeset LC_{CTYPE,COLLATE}=C
		typeset name
		for name; do
			[[ $name == [[:alpha:]_]*([[:alnum:]_]) ]] || return 1
		done
	}

	# Create an associative array with keys filled from the given array
	function arrayToSet {
		checkValidNames "$1" "$2" || return
		nameref pIn=$1 pOut=$2
		# eval "$(printf 'pOut[%q]= ' "${pIn[@]}")"
		eval "pOut+=($(printf '[%q]= ' "${pIn[@]}"))"
	}

	# Shell configuration that applies to all environments.
	function setupUniversalOptions {
		stty -ixon -ctlecho
		shopt -u interactive_comments lithist
		shopt -s extglob lastpipe globstar expand_aliases cmdhist histappend checkwinsize 2>/dev/null
		set -o vi                        # Set interactive vi mode.
		set +o histexpand                # Disable history expansion.
		set -b                           # Immediate job completion notification.
		[[ $EUID == 0 ]] && ulimit -n 8196
		return 0
	}

	# Set env vars that always apply to this user's interactive shells.
	function setupUniversalEnvironment {
		export LC_COLLATE=C LC_CTYPE=en_US.UTF-8
		unset -v HOME GCC_SPECS "${!LD_@}"; export HOME=~
		stripTildesFromColonDelimitedFields PATH || echo 'PATH was modified to remove tildes!' >&2 

		if shopt -q login_shell; then
			if [[ ${EUID:=$(id -u)} == 0 ]]; then
				command cd -- ~ormaaj
			elif [[ $PWD != "$HOME" ]]; then
				command cd
			fi
		fi
		
		unset -v PYTHONPATH
		export XMLLINT_INDENT='    '     # Make the xmllint formatter use 4-space indents.
		export COMP_CVS_REMOTE=1         # Access remotely checked-out files over passwordless ssh for CVS
		export COMP_CONFIGURE_HINTS=1    # Avoid stripping description in --option=description of './configure --help'
		export COMP_TAR_INTERNAL_PATHS=1 # Define to avoid flattening internal contents of tar files
		export MONO_USE_LLVM=1
		[[ $TERM == linux ]] && export TERM=linux-16color # If this is a real linux VT then allow 16 colors (default is 8).

		declare -g \
			PAGER=nvimpager \
			PROMPT_DIRTRIM=3 \
			HISTSIZE=10000000 \
			HISTTIMEFORMAT='%c ' \
			PROMPT_COMMAND='history -a'

	}
	
	function setupPrompt {
		if ret=$? let "ret || $(tput colors) >= 8"; then
			if [[ ${EUID:-$(id -u)} == 0 ]]; then
				declare -g PS1='\[\033[01;31m\]\h\[\033[01;34m\] \W \$\[\033[00m\] '
			else
				declare -g PS1='\[\033[01;32m\]\u@\h\[\033[01;34m\] \w \$\[\033[00m\] '
			fi
		elif [[ ${EUID:-$(id -u)} == 0 ]]; then
		    declare -g PS1='\u@\h \W \$ '
		else
		    declare -g PS1='\u@\h \w \$ '
		fi
	}

	function setupGpgAgent {
		# gpg-agent uses .gnupg but won't create the directory itself for new users.
		if ! { [[ -d ~/.gnupg ]] || mkdir -p -- ~/.gnupg; }; then
			printf 'bashrc: %s\n' 'No ~/.gnupg directory exists and failed to create it.' >&2
			return 1
		fi

		if [[ -t 0 ]] && { GPG_TTY=$(readlink -sne /dev/fd/0) || GPG_TTY=$(tty); }; then
			export GPG_TTY
		else
			unset -v GPG_TTY
		fi

		if gpg-connect-agent /bye; then
			unset -v SSH_AGENT_PID
			typeset sock=~/.gnupg/S.gpg-agent.ssh
			[[ ${BASHPID:-$$} != "${gnupg_SSH_AUTH_SOCK_by}" && -S $sock ]] &&
				export SSH_AUTH_SOCK=$sock
		else
			printf 'gpg-connect-agent failed with status %s.\n' "$?" >&2
			return 1
		fi
	}

	function setupDbusSessionBus {
		if [[ -n $DBUS_SESSION_BUS_ADDRESS ]]; then
			return 0
		elif typeset dbusEnv; ! { dbusEnv=$(dbus-launch --sh-syntax) && eval "$dbusEnv"; }; then
			printf 'dbus-launch failed with status %s.\n' "$?" >&2
			return 1
		fi
	}

	# It's safer to just drop fields from conetxts in which Bash performs an
	# implicit tilde expansion such as PATH and CDPATH (which is in turn determined
	# by HOME). Returns 1 if fields from any of the given vars were modified.
	function stripTildesFromColonDelimitedFields {
		typeset -a pathComponents
		typeset field ret=0

		nameref __var
		for __var; do 
			printf -- %s "${__var}" | IFS= read -rd '' -a pathComponents
			field= __var=
			for field in "${pathComponents[@]}"; do
				if [[ $field == *\~* ]]; then
					ret=1
					continue
				else
					__var+=$field
				fi
			done
		done

		return "$ret"
	}

	# function libraries to source if this file was sourced non-interactively
	function sourceNonInteractiveFuncs {
		isValidNames "$1" || return
		nameref _rootPath=$1
		# Source the general-purpose function library.
		if ! source "${_rootPath}/functions"; then
			printf 'Warning: sourcing function library returned nonzero status for the path: %q\n' "${myRootPath}/interactivefunctions" >&2
			return 1
		fi
	}

	# Source the appropriate libraries for the current runtime environment.
	function sourceInteractiveFuncs {
		isValidNames "$1" || return
		nameref _rootPath=$1

		# Source libraries of functions for interactive use. Platform-specific
		# setup and function definitions are first so they're available to the
		# common interactive library.
		case ${OSTYPE:-$(uname -o)} in
			[Cc]ygwin)
				source "${_rootPath}/interactivefunctions-cygwin" || return
				setupCygwin
				;;
			GNU/Linux|linux-gnu)
				source "${_rootPath}/interactivefunctions-linux" || return
				#setupLinux
				;;
			*)
				echo 'Error: Unknown OSTYPE, not sourcing functions.' >&2
				return 1
		esac

		source "${_rootPath}/interactivefunctions-common" || return

		typeset sh
		for sh in /etc/bash/bashrc.d/* ; do
			source "${sh}"
		done
	}

	# Do this last to avoid modifying functions.
	function setupInteractiveAliases {
		shopt -s expand_aliases

		alias \
			ls='ls -h --color=always --group-directories-first --classify' \
			grep='grep --color=always' \
			tree='tree -ugphDC' \
			curl='curl --xattr' \
			info='info --vi-keys' \
			vim=nvim \
			bash='bash -O extglob -O lastpipe -O expand_aliases' \
			brc='source ~/.bashrc' \
			gdb='gdb -q' \
			env-update='env-update && . /etc/profile' \
			gccflags='AR=gcc-ar NM=gcc-nm RANLIB=gcc-ranlib \
				CFLAGS="-flto=16 -ggdb -floop-strip-mine -pipe -fuse-linker-plugin -floop-block -floop-interchange -Ofast -march=native" \
				CXXFLAGS=$CFLAGS LDFLAGS="-Wl,-O1,-z,lazy,-z,relro,--as-needed,--sort-common,--hash-style=gnu ${CFLAGS}" \
				CPPFLAGS="-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2"'
	}
}

function main {
	if ! { rootPath=$(dirname "$(readlink -snf -- "$BASH_SOURCE")")/shell && [[ -d $rootPath ]]; }; then
		echo 'Failed while attempting to locate the dotfiles path. Cannot source functions.' >&2
		return 1
	fi

	unset -f main
	mainBashrcFuncs # Define all internal functions
	typeset -a bashrcInternalFunctions
	compgen -A function | mapfile -t bashrcInternalFunctions

	typeset -a bashrcFuncCalls

	# Source non-interactive functions unconditionally before interactive ones
	bashrcFuncCalls+=(
		'sourceNonInteractiveFuncs rootPath'
	)

	if [[ $- == *i* ]]; then
		if shopt -q login_shell; then
			bashrcFuncCalls+=(
				setupDbusSessionBus
				setupGpgAgent
			)
		fi
	
		bashrcFuncCalls+=(
			setupUniversalOptions
			setupUniversalEnvironment
			'sourceInteractiveFuncs rootPath'
			setupPrompt
			setupInteractiveAliases # Make sure this is last
		)
	fi

	typeset ifun
	for ifun in "${bashrcFuncCalls[@]}"; do
		# Some libraries have dependencies on others so we have to bail out if anything fails.
		if ! eval "${ifun}"; then
			printf -- 'bashrc fatal error: function %s returned nonzero status: %d\n' "$ifun" "$?" >&2
			return 1
		fi
	done

	unset -f "${bashrcInternalFunctions[@]}"
}

main "$@"

# vim: set fenc=utf-8 ff=unix ft=sh :
