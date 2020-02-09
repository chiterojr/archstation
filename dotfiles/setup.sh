#!/bin/sh
DIR=$(readlink -f `dirname "$0"`)
DOTFILES_ROOT=$(dirname "$DIR")
echo $DIR
echo

find -H "$DIR" -maxdepth 5 | while read -r src; do
  # skip the first iteration
  [[ "$src" == "$DIR" ]] && continue

  # create a destination var for both, symlinks and mkdirs
  dst="$HOME/${src//"$DIR/"/}"

  if [[ -f $src ]]; then
    [[ -e $dst ]] && rm $dst
    ln -s $src $dst
  else
    mkdir -p $dst
  fi
done