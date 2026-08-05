use ../lib/types.nu [mk-task, mk-result]

const task_type = "bootstrap_aur"
const task_label = "aur: bootstrap helpers"

def command-exists [command: string] {
  not (which $command | is-empty)
}

def package-installed [package: string] {
  (^pacman -Q $package | complete).exit_code == 0
}

def failed [detail: string] {
  mk-result $task_type $task_label "failed" $detail
}

def remove-workdir [workdir: string] {
  if ($workdir | str starts-with "/tmp/") {
    ^rm -rf $workdir
  }
}

def build-aur-package [package: string] {
  let workdir = (^mktemp -d "/tmp/archstation-aur.XXXXXX" | str trim)
  let repo_dir = $"($workdir)/($package)"
  let clone = ^git clone $"https://aur.archlinux.org/($package).git" $repo_dir | complete

  if $clone.exit_code != 0 {
    remove-workdir $workdir
    { success: false, detail: ($clone.stderr | str trim) }
  } else {
    let build = do {
      cd $repo_dir
      ^makepkg -si --noconfirm | complete
    }
    let detail = ([$build.stderr $build.stdout] | str join "\n" | str trim)
    remove-workdir $workdir

    { success: ($build.exit_code == 0), detail: $detail }
  }
}

def install-prerequisites [] {
  let dependencies = ["git" "base-devel"]
  let missing = $dependencies | where { |package| not (package-installed $package) }

  if ($missing | is-empty) {
    { success: true, detail: "" }
  } else {
    let args = ["-S" "--needed" "--noconfirm"] | append $missing
    let result = ^sudo pacman ...$args | complete

    {
      success: ($result.exit_code == 0)
      detail: ($result.stderr | str trim)
    }
  }
}

def install-primary [package: string, command: string] {
  let result = build-aur-package $package

  if not $result.success {
    failed $result.detail
  } else if not (command-exists $command) {
    failed $"($command) não foi encontrado após a compilação de ($package)"
  } else {
    null
  }
}

def install-fallback [helper: string, package: string, fallback: string] {
  let result = ^$helper -S --needed --noconfirm $package | complete

  if $result.exit_code != 0 {
    failed ($result.stderr | str trim)
  } else {
    mk-result $task_type $task_label "executed" $"($fallback) instalado usando ($helper)"
  }
}

def run-bootstrap [config: record] {
  let helper = $config.aur_helper
  let helper_package = $config.aur_helper_package
  let fallback = $config.aur_fallback
  let fallback_package = $config.aur_fallback_package

  if ((^id -u | str trim) == "0") {
    return (failed "makepkg não deve ser executado como root")
  }

  let helper_exists = command-exists $helper
  let fallback_exists = command-exists $fallback

  if $helper_exists and $fallback_exists {
    return (mk-result $task_type $task_label "skipped" $"($helper) e ($fallback) já estão instalados")
  }

  let prerequisites = install-prerequisites
  if not $prerequisites.success {
    return (failed $prerequisites.detail)
  }

  if not (command-exists $helper) {
    let primary_result = install-primary $helper_package $helper
    if $primary_result != null {
      return $primary_result
    }
  }

  if not (command-exists $fallback) {
    return (install-fallback $helper $fallback_package $fallback)
  }

  mk-result $task_type $task_label "executed" $"($helper) e ($fallback) estão disponíveis"
}

export def generate [config: record] {
  [(mk-task $task_type $task_label { run-bootstrap $config })]
}

export def check [config: record] {
  let helper_installed = command-exists $config.aur_helper
  let fallback_installed = command-exists $config.aur_fallback

  [{
    task_type: $task_type
    label: $task_label
    status: (if $helper_installed and $fallback_installed { "ok" } else { "missing" })
    detail: $"($config.aur_helper) + ($config.aur_fallback)"
  }]
}
