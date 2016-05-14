#!/bin/ksh

set +o posix
shopt -s extglob lastpipe

function main {
	typeset myRootPath
	if myRootPath=$(dirname "$(readlink -snf -- "$BASH_SOURCE")") && [[ -d $myRootPath ]]; then
		source "${myRootPath}/functions" || return
		unset -f main
	else
		return 1
	fi
}

main

function tmuxUpdateGlobalEnv {
	if [[ -z $TMUX ]]; then
		echo 'TMUX variable appears to be undefined or empty - not updating the environment.' >&2
		return 1
	elif [[ $(type -t getEnv) != function ]]; then
		tmux display 'getEnv function undefined - could not update the environment.'
		return 1
	else
		typeset msg ret=0
		if [[ ${EUID:-$(id -u)} != 0 ]]; then
			if env-update 2>/dev/null
			then msg='Updated global system environment.'
			else msg='env-update failed. Could not update system environment as root user.' ret=$?
			fi
		fi

		if (
			unset -v doXtrace
			[[ -o xtrace ]] && doXtrace=
			exec -c -- bash -O lastpipe -O extglob ${doXtrace+'-x'} /dev/fd/3 "$(typeset -fp getEnv)" "$TMUX"
		)
		then msg+="${msg:+ }Updated global tmux environment."
		else msg+="${msg:+ }Failed updating global tmux environment." ret=$?
		fi 3<<-'EOF'
			source /etc/profile
			eval -- "$1" || exit
			typeset -A _myEnv
			getEnv _myEnv || exit
			export TMUX=$2 
			typeset _key
			for _key in "${!_myEnv[@]}"; do
				tmux setenv -g "$_key" "${_myEnv[$_key]}"
			done
		EOF
		tmux display -- "$msg"
		return "$ret"
	fi
}

# vim: set fenc=utf-8 ff=unix ft=sh ts=4 sts=1 sw=4 noet :
