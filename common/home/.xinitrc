function xinitrc_main {
	typeset myRootPath
	if myRootPath=$(dirname "$(readlink -snf -- "$BASH_SOURCE")") && [[ -d $myRootPath ]]; then
		source "${myRootPath}/shell/functions"
		exec startkde
	fi
}

xinitrc_main
