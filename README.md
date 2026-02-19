# archstation

Personal Arch Linux workstation orchestrator written in Nushell.

A minimal, opinionated system that automates workstation setup: installing packages, deploying dotfiles, enabling services, and configuring user groups. Designed for personal use as a simpler alternative to Ansible, with two-way sync capabilities.

## Usage

```nu
nu setup.nu            # show help
nu setup.nu up         # execute all tasks
nu setup.nu preview    # dry-run, show what would run
nu setup.nu status     # check current state (read-only)
nu setup.nu ingest     # absorb system changes back into the repo
```

## Project structure

```
setup.nu              Orchestrator: dispatches commands to task modules
config.yml            Declares which tasks to run and their settings
packages.yml          Package list organized by category
dotfiles/             Config files mirroring ~/ structure
lib/
  types.nu            Core types: mk-task, mk-result
  runner.nu           Sequential task executor with fail-fast
tasks/
  install_pkg.nu      Package installation (pacman + AUR)
  copy_dotfile.nu     Dotfile deployment with hash-based safety
  enable_service.nu   Systemd service activation
  add_user_to_group.nu  User group membership
  mod.nu              Module re-exports
```

## Architecture

### Task contract

Every task module in `tasks/` exports up to three functions:

| Function | Purpose | Required |
|----------|---------|----------|
| `generate` | Returns a list of executable task records for `up` | Yes |
| `check` | Returns a list of status records for `status` | Yes |
| `ingest` | Interactive reverse-sync from system to repo | Optional |

Each function receives a `config: record` with the task's settings from `config.yml`.

### Execution model

The orchestrator (`setup.nu`) reads `config.yml` and dispatches each task type to its corresponding module via static `match` blocks. There is one dispatch function per operation (`dispatch`, `dispatch-check`, `dispatch-ingest`).

```
config.yml
    │
    ▼
 setup.nu (dispatch)
    │
    ├── tasks/install_pkg.nu     generate → [task, task, ...]
    ├── tasks/copy_dotfile.nu    generate → [task, task, ...]
    ├── tasks/enable_service.nu  generate → [task, task, ...]
    └── tasks/add_user_to_group.nu generate → [task, task, ...]
            │
            ▼
      lib/runner.nu (sequential execution, fail-fast)
```

### Task record

Every task produced by `generate` is a record with three fields:

```nu
{ task_type: "install_pkg", label: "pkg: git", execute: {|| ...closure... } }
```

The runner calls each closure sequentially. Each closure returns a result record:

```nu
{ task_type: "install_pkg", label: "pkg: git", status: "executed", detail: "sudo pacman -S --noconfirm git" }
```

Status is one of:
- **executed** - action was performed successfully
- **skipped** - already in desired state, nothing to do
- **failed** - error occurred, execution stops immediately (fail-fast)

### Configuration

`config.yml` maps task types to their settings. Tasks run in declaration order:

```yaml
tasks:
  install_pkg:
    source: packages.yml       # where to read the package list
    aur_helper: paru           # primary AUR helper
    aur_fallback: yay          # fallback if primary fails
  copy_dotfile:
    source_dir: dotfiles       # repo directory with dotfiles
    dest_dir: "~"              # deployment target
  enable_service:
    services: [docker, tailscaled, ollama]
  add_user_to_group:
    groups: [docker]
```

## Task types

### install_pkg

Installs packages via pacman or AUR helper. Reads `packages.yml`, which organizes packages by category:

```yaml
packages:
  base:
    - base-devel
    - git
  desktop:
    - hyprland --aur
    - waybar --needed pipewire-jack
```

Flags:
- `--aur` - install via AUR helper instead of pacman
- `--needed <dep>` - pass additional dependency to pacman

### copy_dotfile

Deploys config files from `dotfiles/` to `~/`, mirroring the directory structure. Uses SHA256 hash comparison:
- **Destination missing** - copies the file (creates parent dirs)
- **Destination matches** - skips (already in sync)
- **Destination differs** - fails with SAFETY error (use `ingest` to resolve)

### enable_service

Enables and starts systemd services listed in `config.yml`. Skips services that are already active.

### add_user_to_group

Adds the current user to system groups listed in `config.yml`. Skips groups where the user is already a member.

## Ingest (two-way sync)

The `ingest` command absorbs changes made manually on the system back into the repo.

### install_pkg

Detects orphan packages (installed via `pacman -Qe` but not in `packages.yml`). Presents an interactive multi-select list where the user toggles packages with SPACE and confirms with ENTER. Selected packages are appended as text to an `ingested:` section in `packages.yml`, preserving existing formatting and comments.

### copy_dotfile

Finds managed dotfiles where the system copy differs from the repo. For each divergent file, shows a unified diff and offers three choices: update the repo, skip, or view the full diff before deciding.

### Tasks without ingest

`enable_service` and `add_user_to_group` do not support ingest. Infrastructure changes (services, groups) should be edited directly in `config.yml`.

## Adding a new task type

1. Create `tasks/my_task.nu` exporting `generate` and `check` (and optionally `ingest`)
2. Add `export use my_task.nu` to `tasks/mod.nu`
3. Add a branch to each `dispatch` function in `setup.nu`
4. Add the task configuration to `config.yml`
