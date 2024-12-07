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

# loading personal bin filder
export PATH="$PATH:$HOME/dev/bin"

# globally (local) npm modules
export PATH="$PATH:$HOME/.npm-packages/bin"

# configure golang
export GOPATH="$HOME/.golang"
export PATH="$PATH:$GOPATH/bin"

# haskell and ghcup
export PATH="$PATH:$HOME/.ghcup/bin"

# rust cargo
export PATH="$PATH:$HOME/.cargo/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
