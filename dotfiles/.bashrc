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

# for wayland
export GDK_BACKEND=wayland

# configure personal binary directories
export PATH="$PATH:$HOME/bin"
export PATH="$PATH:$HOME/bin/scripts"

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

# bun user "global"
export PATH="/home/junior/.bun/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/zfs_home/bin/google-cloud-sdk/path.bash.inc' ]; then . '/zfs_home/bin/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/zfs_home/bin/google-cloud-sdk/completion.bash.inc' ]; then . '/zfs_home/bin/google-cloud-sdk/completion.bash.inc'; fi



[ -f "$HOME/dev/.bashrc-extension" ] && source "$HOME/dev/.bashrc-extension"


# Created by `pipx` on 2025-12-17 15:43:42
export PATH="$PATH:/home/junior/.local/bin"
