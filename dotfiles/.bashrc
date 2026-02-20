#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ----------------------------------------
# SHELL
# ----------------------------------------
alias ls='ls --color=auto'
parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
export PS1="\u@\h \[\033[32m\]\W\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "
export GDK_BACKEND=wayland

# ----------------------------------------
# PERSONAL BINARY DIRECTORIES
# ----------------------------------------
export PATH="$PATH:$HOME/bin"
export PATH="$PATH:$HOME/bin/scripts"
export PATH="$PATH:$HOME/bin/scripts/symbin"
export PATH="$PATH:$HOME/.local/bin"

# ----------------------------------------
# LANGUAGE TOOLCHAINS
# ----------------------------------------
export GOPATH="$HOME/.golang"
export PATH="$PATH:$GOPATH/bin"
export PATH="$PATH:$HOME/.npm-packages/bin"
export PATH="$PATH:$HOME/.ghcup/bin"
export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:$HOME/.bun/bin"

# ----------------------------------------
# GOOGLE CLOUD SDK
# ----------------------------------------
if [ -f '/zfs_home/bin/google-cloud-sdk/path.bash.inc' ]; then . '/zfs_home/bin/google-cloud-sdk/path.bash.inc'; fi
if [ -f '/zfs_home/bin/google-cloud-sdk/completion.bash.inc' ]; then . '/zfs_home/bin/google-cloud-sdk/completion.bash.inc'; fi

# ----------------------------------------
# EXTENSIONS
# ----------------------------------------
[ -f "$HOME/dev/.bashrc-extension" ] && source "$HOME/dev/.bashrc-extension"
