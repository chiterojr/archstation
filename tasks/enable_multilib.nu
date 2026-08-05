use ../lib/types.nu [mk-task, mk-result]

const task_type = "enable_multilib"
const task_label = "repo: multilib"

def enabled [config_path: string] {
  let lines = open --raw $config_path | lines
  mut in_multilib = false

  for line in $lines {
    let trimmed = $line | str trim

    if $trimmed == "[multilib]" {
      $in_multilib = true
      continue
    }

    if $in_multilib and ($trimmed | str starts-with "[") {
      return false
    }

    if $in_multilib and ($trimmed | str starts-with "Include") and ($trimmed | str contains "/etc/pacman.d/mirrorlist") {
      return true
    }
  }

  false
}

def failed [detail: string] {
  mk-result $task_type $task_label "failed" $detail
}

def enable [config_path: string] {
  let raw = open --raw $config_path
  let pattern = '(?m)^#?[ \t]*\[multilib\][ \t]*\n#?[ \t]*Include[ \t]*=[ \t]*/etc/pacman\.d/mirrorlist[ \t]*'
  let replacement = "[multilib]\nInclude = /etc/pacman.d/mirrorlist"
  let updated = $raw | str replace -r $pattern $replacement

  if $updated == $raw {
    return (failed $"A seção [multilib] não foi encontrada em ($config_path)")
  }

  let temp_path = (^mktemp "/tmp/archstation-pacman.XXXXXX" | str trim)
  $updated | save --force $temp_path

  let install = ^sudo install -m 644 $temp_path $config_path | complete
  ^rm -f $temp_path

  if $install.exit_code != 0 {
    return (failed ($install.stderr | str trim))
  }

  if not (enabled $config_path) {
    return (failed $"[multilib] não foi habilitado em ($config_path)")
  }

  mk-result $task_type $task_label "executed" "[multilib] habilitado"
}

def execute-task [config: record] {
  let config_path = $config.pacman_conf

  if (enabled $config_path) {
    return (mk-result $task_type $task_label "skipped" "[multilib] já está habilitado")
  }

  enable $config_path
}

export def generate [config: record] {
  [(mk-task $task_type $task_label { execute-task $config })]
}

export def check [config: record] {
  let config_path = $config.pacman_conf

  [{
    task_type: $task_type
    label: $task_label
    status: (if (enabled $config_path) { "ok" } else { "missing" })
    detail: $config_path
  }]
}
