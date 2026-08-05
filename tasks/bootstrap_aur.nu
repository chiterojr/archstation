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

def install-helper [package: string, command: string] {
  let result = build-aur-package $package

  if not $result.success {
    failed $result.detail
  } else if not (command-exists $command) {
    failed $"($command) não foi encontrado após a compilação de ($package)"
  } else {
    null
  }
}

def run-bootstrap [config: record] {
  let helper = $config.aur_helper
  let helper_package = $config.aur_helper_package

  if ((^id -u | str trim) == "0") {
    return (failed "makepkg não deve ser executado como root")
  }

  if (command-exists $helper) {
    return (mk-result $task_type $task_label "skipped" $"($helper) já está instalado")
  }

  let prerequisites = install-prerequisites
  if not $prerequisites.success {
    return (failed $prerequisites.detail)
  }

  let install_result = install-helper $helper_package $helper
  if $install_result != null {
    return $install_result
  }

  if not (command-exists $helper) {
    return (failed $"($helper) não foi encontrado após a compilação de ($helper_package)")
  }

  mk-result $task_type $task_label "executed" $"($helper) instalado"
}

export def generate [config: record] {
  [(mk-task $task_type $task_label { run-bootstrap $config })]
}

export def check [config: record] {
  let helper_installed = command-exists $config.aur_helper

  [{
    task_type: $task_type
    label: $task_label
    status: (if $helper_installed { "ok" } else { "missing" })
    detail: $config.aur_helper
  }]
}
