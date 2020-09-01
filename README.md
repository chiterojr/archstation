# Intro

A project that sets up my Arch Linux workstation.

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

