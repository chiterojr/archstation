use ../lib/types.nu [mk-task, mk-result]

export def generate [config: record] {
  $config.services | each { |service|
    let label = $"service: ($service)"

    mk-task "enable_service" $label {
      let check = ^systemctl is-enabled $service | complete
      if $check.exit_code == 0 {
        mk-result "enable_service" $label "skipped" "already enabled"
      } else {
        let result = ^sudo systemctl enable --now $service | complete
        if $result.exit_code == 0 {
          mk-result "enable_service" $label "executed" $"sudo systemctl enable --now ($service)"
        } else {
          mk-result "enable_service" $label "failed" ($result.stderr | str trim)
        }
      }
    }
  }
}

export def check [config: record] {
  $config.services | each { |service|
    let label = $"service: ($service)"
    let enabled = (^systemctl is-enabled $service | complete).exit_code == 0
    let active = (^systemctl is-active $service | complete).exit_code == 0

    let status = if $enabled and $active {
      "ok"
    } else if $enabled {
      "enabled, not active"
    } else {
      "disabled"
    }

    { task_type: "enable_service", label: $label, status: $status, detail: "" }
  }
}
