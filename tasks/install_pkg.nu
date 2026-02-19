use ../lib/types.nu [mk-task, mk-result]

export def generate [config: record] {
  let aur_helper = $config.aur_helper
  let aur_fallback = $config.aur_fallback

  let sync_task = mk-task "install_pkg" "pkg: sync database" {
    let result = ^sudo pacman -Sy | complete
    if $result.exit_code == 0 {
      mk-result "install_pkg" "pkg: sync database" "executed" "sudo pacman -Sy"
    } else {
      mk-result "install_pkg" "pkg: sync database" "failed" ($result.stderr | str trim)
    }
  }

  let pkg_tasks = open $config.source
    | get packages
    | values
    | flatten
    | each { |entry|
        let parts = $entry | split row ' '
        let pkg_name = $parts.0
        let flags = $parts | skip 1
        let is_aur = ($flags | any { |f| $f == "--aur" })
        let label = $"pkg: ($pkg_name)"

        mk-task "install_pkg" $label {
          let check = ^pacman -Q $pkg_name | complete
          if $check.exit_code == 0 {
            mk-result "install_pkg" $label "skipped" "already installed"
          } else if $is_aur {
            let install = ^$aur_helper -S --noconfirm $pkg_name | complete
            if $install.exit_code == 0 {
              mk-result "install_pkg" $label "executed" $"($aur_helper) -S --noconfirm ($pkg_name)"
            } else {
              let fallback = ^$aur_fallback -S --noconfirm $pkg_name | complete
              if $fallback.exit_code == 0 {
                mk-result "install_pkg" $label "executed" $"($aur_fallback) -S --noconfirm ($pkg_name)"
              } else {
                mk-result "install_pkg" $label "failed" ($fallback.stderr | str trim)
              }
            }
          } else {
            let extra_args = $flags | where { |f| $f != "--aur" }
            let args = ["-S" "--noconfirm" $pkg_name] | append $extra_args
            let install = ^sudo pacman ...$args | complete
            if $install.exit_code == 0 {
              mk-result "install_pkg" $label "executed" $"sudo pacman ($args | str join ' ')"
            } else {
              mk-result "install_pkg" $label "failed" ($install.stderr | str trim)
            }
          }
        }
    }

  [$sync_task] | append $pkg_tasks
}

export def check [config: record] {
  open $config.source
  | get packages
  | values
  | flatten
  | each { |entry|
      let pkg_name = $entry | split row ' ' | first
      let is_aur = ($entry | str contains "--aur")
      let installed = (^pacman -Q $pkg_name | complete).exit_code == 0
      let status = if $installed { "ok" } else { "missing" }

      { task_type: "install_pkg", label: $"pkg: ($pkg_name)", status: $status, detail: (if $is_aur { "aur" } else { "pacman" }) }
  }
}
