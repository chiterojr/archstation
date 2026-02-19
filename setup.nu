#!/usr/bin/env nu

use lib
use tasks

def dispatch [task_type: string, task_config: record] {
  match $task_type {
    "install_pkg" => (tasks install_pkg generate $task_config),
    "copy_dotfile" => (tasks copy_dotfile generate $task_config),
    "enable_service" => (tasks enable_service generate $task_config),
    "add_user_to_group" => (tasks add_user_to_group generate $task_config),
    _ => {
      print $"(ansi red)unknown task type: ($task_type)(ansi reset)"
      []
    }
  }
}

def dispatch-check [task_type: string, task_config: record] {
  match $task_type {
    "install_pkg" => (tasks install_pkg check $task_config),
    "copy_dotfile" => (tasks copy_dotfile check $task_config),
    "enable_service" => (tasks enable_service check $task_config),
    "add_user_to_group" => (tasks add_user_to_group check $task_config),
    _ => {
      print $"(ansi red)unknown task type: ($task_type)(ansi reset)"
      []
    }
  }
}

# TODO: dispatch, dispatch-check, and dispatch-ingest share the same static match
# pattern. If more operations are added, consider refactoring into a single dynamic
# dispatch mechanism (e.g. a record-based registry per task module).
def dispatch-ingest [task_type: string, task_config: record] {
  match $task_type {
    "install_pkg" => (tasks install_pkg ingest $task_config),
    "copy_dotfile" => (tasks copy_dotfile ingest $task_config),
    _ => {
      # Not all tasks support ingest (enable_service, add_user_to_group are intentionally excluded)
      null
    }
  }
}

def "main ingest" [] {
  let config = open config.yml

  print $"(ansi cyan_bold)archstation ingest(ansi reset) - absorb system changes back into the repo"
  print ""

  let separator = 1..60 | each { "=" } | str join

  $config.tasks | items { |task_type, task_config|
    print ""
    print $"(ansi cyan_bold)($separator)(ansi reset)"
    print $"(ansi cyan_bold)  INGEST: ($task_type)(ansi reset)"
    print $"(ansi cyan_bold)($separator)(ansi reset)"
    print ""
    dispatch-ingest $task_type $task_config
  }

  print ""
  print $"(ansi cyan_bold)($separator)(ansi reset)"
  print $"(ansi green)  Ingest complete.(ansi reset)"
  print $"(ansi cyan_bold)($separator)(ansi reset)"
}

def "main up" [] {
  let config = open config.yml

  let all_tasks = $config.tasks | items { |task_type, task_config|
    print $"(ansi cyan_bold)--- ($task_type) ---(ansi reset)"
    dispatch $task_type $task_config
  } | flatten

  print ""
  print $"(ansi cyan_bold)--- execution ---(ansi reset)"
  lib runner run-tasks $all_tasks
}

def "main preview" [] {
  let config = open config.yml

  let all_tasks = $config.tasks | items { |task_type, task_config|
    dispatch $task_type $task_config
  } | flatten

  $all_tasks | select task_type label | table
}

def colorize-check [status: string] {
  match $status {
    "ok" => $"(ansi green)($status)(ansi reset)",
    "missing" => $"(ansi red)($status)(ansi reset)",
    "differs" => $"(ansi yellow)($status)(ansi reset)",
    "disabled" => $"(ansi red)($status)(ansi reset)",
    _ => $"(ansi yellow)($status)(ansi reset)",
  }
}

def "main status" [] {
  let config = open config.yml

  let raw = $config.tasks | items { |task_type, task_config|
    dispatch-check $task_type $task_config
  } | flatten

  let display = $raw | each { |r|
    { label: $r.label, status: (colorize-check $r.status), detail: $r.detail }
  }

  print ($display | table --expand --width 120)

  let ok_count = $raw | where status == "ok" | length
  let total = $raw | length
  let pending = $total - $ok_count
  print ""
  print $"(ansi cyan_bold)($ok_count)/($total) ok, ($pending) pending(ansi reset)"
}

def main [] {
  print $"(ansi cyan_bold)archstation(ansi reset) - Arch Linux workstation orchestrator"
  print ""
  print "Usage: nu setup.nu <command>"
  print ""
  print $"(ansi cyan_bold)Commands:(ansi reset)"
  print "  up         Execute all tasks defined in config.yml"
  print "  preview    Show what would run without executing (dry-run)"
  print "  status     Check current state of all tasks (read-only)"
  print "  ingest     Absorb system changes back into the repo"
  print ""
  print $"(ansi cyan_bold)Task types:(ansi reset)"
  print "  install_pkg        Install packages via pacman or AUR helper (paru/yay)"
  print "  copy_dotfile       Copy dotfiles from dotfiles/ to ~/"
  print "  enable_service     Enable and start systemd services"
  print "  add_user_to_group  Add current user to system groups"
  print ""
  print $"(ansi cyan_bold)Configuration:(ansi reset)"
  print "  config.yml         Defines which tasks to run and their settings"
  print "  packages.yml       Package list (--aur for AUR, --needed for deps)"
  print "  dotfiles/          Directory structure mirroring ~/"
  print ""
  print $"(ansi cyan_bold)Execution contract:(ansi reset)"
  print $"  Every task returns one of:"
  print $"    (ansi green)executed(ansi reset)  - action was performed successfully"
  print $"    (ansi yellow)skipped(ansi reset)   - already in desired state"
  print $"    (ansi red)failed(ansi reset)    - error occurred, execution stops \(fail-fast\)"
}
