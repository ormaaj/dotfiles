[[ $- == *i* ]] || return

function main {
	unset -v PYTHONPATH
	typeset -f +t "$FUNCNAME"
	trap 'trap - RETURN; unset -f "$FUNCNAME"' RETURN
	stty -ixon -ctlecho
	shopt -u interactive_comments
	set -o vi
	set +o histexpand

	export XMLLINT_INDENT='    '     # Make the xmllint formatter use 4-space indents.
	export COMP_CVS_REMOTE=1         # Access remotely checked-out files over passwordless ssh for CVS
	export COMP_CONFIGURE_HINTS=1    # Avoid stripping description in --option=description of './configure --help'
	export COMP_TAR_INTERNAL_PATHS=1 # Define to avoid flattening internal contents of tar files

	typeset _dotfilesRootPath
	if _dotfilesRootPath=$(dirname "$(readlink -snf "$BASH_SOURCE")") && ! ${_dotfilesRootPath:+false}; then
		# Source the general-purpose function library.
		command . "${_dotfilesRootPath}/functions" || printf 'Warning: sourcing function library returned nonzero status for the path: %q\n' "${_dotfilesRootPath}/interactivefunctions" >&2

		# Source the library of functions intended for interactive use.
		if command . "${_dotfilesRootPath}/interactivefunctions"; then
			# Do platform-specific setup
			conditionalDefine
		else
			printf 'Warning: sourcing interactive functions returned nonzero for the path: %q\n' "${_dotfilesRootPath}/interactivefunctions" >&2
		fi
	else
		echo 'Failed while attempting to locate the dotfiles path. Cannot source functions.' >&2
	fi

	# If this is a real linux VT then allow 16 colors (default is 8) and swap caps-lock / escape keys
	if [[ $TERM == linux ]]; then
		export TERM=linux-16color
		loadkeys -
	fi <<\EOF 2>/dev/null
keycode 1 = Caps_Lock
keycode 58 = Escape
EOF
}

# If we want to show error output only if reloading this file via the `brc' wrapper.
#if [[ ${FUNCNAME[1]} == brc ]]; then
#	main "$@"
#else
#	main "$@" >/dev/null 2>&1
#fi

main "$@"

# vim: set fenc=utf-8 ff=unix :
