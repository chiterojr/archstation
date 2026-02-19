# archstation

Personal Arch Linux workstation orchestrator written in Nushell.

A minimal, opinionated task runner that automates system setup: installing packages, deploying dotfiles, enabling services, and configuring user groups. Designed for personal use as a simpler alternative to Ansible.

## Usage

```nu
nu setup.nu            # show help
nu setup.nu up         # execute all tasks
nu setup.nu preview    # dry-run, show what would run
nu setup.nu status     # check current state (read-only)
```

## Structure

```
setup.nu          Main orchestrator entry point
config.yml        Defines which tasks to run and their settings
packages.yml      Package list organized by category
dotfiles/         Config files mirroring ~/ structure
lib/              Core library (types, runner)
tasks/            Task modules (one per task type)
```

## Task types

| Task | Description |
|------|-------------|
| `install_pkg` | Install packages via pacman or AUR helper (paru/yay) |
| `copy_dotfile` | Copy dotfiles from `dotfiles/` to `~/` with safety checks |
| `enable_service` | Enable and start systemd services |
| `add_user_to_group` | Add current user to system groups |

## How it works

Every task follows the same execution contract and returns one of three statuses:
- **executed** - action was performed successfully
- **skipped** - already in desired state, nothing to do
- **failed** - error occurred, execution stops immediately (fail-fast)

Tasks are configured in `config.yml` and executed in the order they appear. Adding a new task type requires creating a module in `tasks/` and registering it in `setup.nu`.

## packages.yml flags

- `--aur` - install via AUR helper instead of pacman
- `--needed <dep>` - pass additional dependency to pacman
