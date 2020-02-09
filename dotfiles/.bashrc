#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

# git
parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
export PS1="\u@\h \[\033[32m\]\W\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "

# loading personal script folder
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/dev/scripts"

# globally (local) npm modules
export PATH="$PATH:$HOME/.npm-packages/bin"

# configure golang
export GOPATH="$HOME/dev/go"
export PATH="$PATH:$GOPATH/bin"
