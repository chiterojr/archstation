def mk-ext-cmd [name: string, args: list<string>, sudo: bool] {
  let sudo_to_attach = if $sudo { 'sudo ' } else { '' }
  let full_cmd = $"($sudo_to_attach)($name) ($args | str join ' ')";

  {
    name: $name,
    args: $args,
    sudo: $sudo,
    full_cmd: $full_cmd
  }
}

def mk-task [name, cmd, check_cmd]  {
  {
    name: $name,
    cmd: $cmd,
    skip_check_cmd: $check_cmd
  }
}

def mk-task-result [cmd, status, completed] {
  {
    cmd: $cmd,
    status: ($status | match $in {
      skipped => $"(ansi yellow)skipped(ansi reset)",
      executed => $"(ansi green)executed(ansi reset)",
      failed => $"(ansi red)failed(ansi reset)",
      $unknown => $unknown
    }),
    exit_code: $completed.exit_code,
    stderr: $completed.stderr,
  }
}

def run-cmd [cmd] {
  if $cmd.sudo {
    let args = $cmd.args | prepend $cmd.name
    run-external sudo ...$args | complete
  } else {
    run-external $cmd.name ...$cmd.args | complete
  }
}

def exec-task [task] {
  let check_cmd_completed = run-cmd $task.skip_check_cmd

  $check_cmd_completed

  if $check_cmd_completed.exit_code == 0 {
    mk-task-result $task.cmd.full_cmd skipped $check_cmd_completed
  } else {
    let cmd_completed = run-cmd $task.cmd

    if $cmd_completed.exit_code == 0 {
      mk-task-result $task.cmd.full_cmd executed $cmd_completed
    } else {
      mk-task-result $task.cmd.full_cmd failed $cmd_completed
    }
  }
}

def "main preview" [
  --full # Show a full and verbose version of preview
] {
  parse-pacman-packages |
  each { |task|
    if $full {
      $task
    } else {
      { name: $task.name, cmd: $task.cmd.full_cmd }
    }
  }
}

def "main up" [] {
  parse-pacman-packages |
  each { |task|
    exec-task $task
  }
}

def main [] {
  print help
}

def parse-pacman-packages [] {
  open packages.yml |
  get packages |
  values |
  flatten |
  each { |item|
    $item |
    split row ' ' |
    match $in {
      [$pkg_name "--needed" $needed] =>
        [$pkg_name (mk-ext-cmd pacman ['-S' $pkg_name '--needed' $needed '--noconfirm'] true)],
      [$pkg_name] =>
        [$pkg_name (mk-ext-cmd pacman ['-S' $pkg_name '--noconfirm'] true)],
      [$pkg_name "--yay"] =>
        [$pkg_name (mk-ext-cmd yay ['-S' $pkg_name '--noconfirm'] false)]
    } |
    mk-task 'install-pacman-package' $in.1 (mk-ext-cmd pacman ['-Q' $in.0] false)
  }
}
