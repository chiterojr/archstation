use ../lib/types.nu [mk-task, mk-result]

export def generate [config: record] {
  let username = $env.USER

  $config.groups | each { |group|
    let label = $"group: ($group)"

    mk-task "add_user_to_group" $label {
      let current_groups = ^id -nG $username | complete
      let in_group = $current_groups.stdout | split row ' ' | any { |g| $g == $group }

      if $in_group {
        mk-result "add_user_to_group" $label "skipped" $"($username) already in ($group)"
      } else {
        let result = ^sudo usermod -aG $group $username | complete
        if $result.exit_code == 0 {
          mk-result "add_user_to_group" $label "executed" $"sudo usermod -aG ($group) ($username)"
        } else {
          mk-result "add_user_to_group" $label "failed" ($result.stderr | str trim)
        }
      }
    }
  }
}

export def check [config: record] {
  let username = $env.USER

  $config.groups | each { |group|
    let label = $"group: ($group)"
    let current_groups = ^id -nG $username | complete
    let in_group = $current_groups.stdout | split row ' ' | any { |g| $g == $group }

    {
      task_type: "add_user_to_group",
      label: $label,
      status: (if $in_group { "ok" } else { "missing" }),
      detail: $username
    }
  }
}
