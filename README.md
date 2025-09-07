# Intro

A project that sets up my Arch Linux workstation.

## Notes

Just ramdom notes that need to be better structured elsewhere.

### Locale

To use US keyboard with Intl variant and ç on dead acute, its necessary to
install pt_BR.UTF-8 locale and set it in /etc/locale.conf.

A working keyboard xorg config:

```conf
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "us,us,br"
        # Option "XkbModel" "pc105+inet"
        # Option "XkbOptions" "terminate:ctrl_alt_bksp"
        Option "XkbOptions" "grp:alt_shift_toggle"
        Option "XkbVariant" ",intl,"
EndSection
```

Probably the command to generate the result above:

```bash
localectl --no-convert set-x11-keymap us,us,br pc104 ,intl, grp:alt_shift_toggle
```

## Manual Changes

Configure the correct wlan interface in the dotfiles/.config/polybar/config file:

```
[module/wlan]
type = internal/network
interface = wlp60s0
```

Configure the correct battery interface in the dotfiles/.config/polybar/config file:

```
[module/battery]
type = internal/battery
battery = BAT0
```

Properly configure the video card:
https://wiki.archlinux.org/index.php/NVIDIA_Optimus

## Nushell

To test the new Nushell kit to replace Ansible:

```nu
docker build -t archstation-nushell . ;                                                                                                                                                                    11/12/2024 11:29:16
  docker run --rm -ti --user 1000:1000 -w /home/junior --hostname archstation-nushell -v $"($env.PWD):/home/junior/archstation" archstation-nushell
```
