ls ...(glob dotfiles/**/*) |
where type == file |
get name |
sort |
uniq |
each { | fpath | $fpath }
