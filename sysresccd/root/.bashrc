#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias ll='ls --color=auto -lah'

shopt -s extglob lastpipe; set -o vi; PROMPT_COMMAND='history -a'
