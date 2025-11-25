def mk-task [name, executor] {
  { name: $name, executor: $executor }
}

def mk-exec-result [cmd: string, status: string, completed] {
  {
    cmd: $cmd,
    status: ($status | match $in {
      skipped => $"(ansi yellow)skipped(ansi reset)",
      executed => $"(ansi green)executed(ansi reset)",
      failed => $"(ansi red)failed(ansi reset)"
    }),
    exit_code: $completed.exit_code,
    stderr: $completed.stderr,
  }
}

let dotfiles_tasks = (
  ls ...(glob dotfiles/**/*) |
  where type == file |
  get name |
  sort |
  uniq |
  each { | fpath |
    let taskexecutor = {
      let replacepath = $"($env.PWD)/dotfiles"
      let dest_file_path = $fpath | str replace $replacepath $env.HOME
      let dest_dir_path = $dest_file_path | path split | first (($in | length) - 1) | path join

      # dependency commands
      run-external mkdir "-p" $"($dest_dir_path)" $"($dest_file_path)" | complete
      run-external rm "-rf" $"($dest_file_path)" | complete

      let cmd_args = ["-s" $"($fpath)" $"($dest_file_path)"]
      run-external ln ...$cmd_args | complete | match $in.exit_code {
        0 => (mk-exec-result $"ln ($cmd_args | str join ' ')" executed $in)
      }
    }

    mk-task "symlink a dotfile" $taskexecutor
  }
)

# install packages
let install_packages_tasks = (
  open packages.yml |
  get packages |
  values |
  flatten |
  each { |item|
    let taskexecutor = {
      let pkg_kit = match $item {
        [$pkg] => ($pkg | split row ' ' | { name: $in.0, needed: $in.1 }),
        $name => { name: $name, needed: nothing }
      }

      # let pkg_kit = match $item {
      #     [$name "" ]
      # }

      let full_cmd = match $pkg_kit.needed {
        nothing => [pacman '-S' '--noconfirm' $"($pkg_kit.name)"]
        _ => [pacman '-S' '--noconfirm' $"($pkg_kit.name)" '--needed' $"($pkg_kit.needed)"]
      }
      let full_text_cmd = $full_cmd | str join ' '

      let pkg_check = run-external pacman '-Q' $pkg_kit.name | complete
      if $pkg_check.exit_code == 0 {
        mk-exec-result $"sudo ($full_text_cmd)" skipped $pkg_check
      } else {
        let pkg_install = run-external sudo ...$full_cmd | complete

        if $pkg_install.exit_code == 0 {
          mk-exec-result $"sudo ($full_text_cmd)" executed $pkg_install
        } else {
          mk-exec-result $"sudo ($full_text_cmd) ($pkg_install.stderr | str trim)" failed $pkg_install
        }
      }
    }

    mk-task "install pacman package" $taskexecutor
  } |
  prepend (mk-task "update pacman list" {
    let pacman_update = run-external sudo pacman "-Sy" | complete

    if $pacman_update.exit_code == 0 {
      mk-exec-result 'sudo pacman -Sy' executed $pacman_update
    } else {
      mk-exec-result $"sudo pacman -Sy ($pacman_update.stderr | str trim)" failed $pacman_update
    }
  })
)

# TODO tasks
# - add user to docker group
# - pt_BR locale
# - gsettings set org.gnome.desktop.interface gtk-theme Arc-Dark

[
  #$dotfiles_tasks
  $install_packages_tasks
] | flatten | each while { |task|
  let result = (do $task.executor)

  if $result.status != failed {
    $result
  }
  # do $task.executor | match $in.status {
  #   failed => (exit 1),
  #   _ => $in
  # }
}
