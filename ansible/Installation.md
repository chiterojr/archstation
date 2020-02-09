# Arch Linux Installation Guide

## Partitioning and Formatting the Hard Drive

See the list of the disks in the device, if the target drive is not GPT then convert
it with *gdisk*<br />
`fdisk -l`

Open the partition manager in the disk you want to install<br />
`cfdisk /dev/sdx`

Create the partitions using the tool then hit enter on [Write]

- Create a partition of 300M for EFI with `EFI System` as type
- Create one partition of 2xMemorySize for swap with `Linux swap` as type
- Create another partition for your system with `Linux filesystem` as type

Format the EFI partition<br />
`mkfs.fat -F32 /dev/sdx1`

Format the swap partition<br />
`mkswap /dev/sdx2`

Format the system partition<br />
`mkfs.ext4 /dev/sdx3`

Activate the swap partition<br />
`swapon /dev/sdaX`

## Installing the System

Mount the root on /mnt<br />
`mount /dev/sdx3 /mnt`

To install the system ont root partition internet connection is needed, for cable
connections use `dhcp` and for wifi use `wifi-menu`

Use pacstrap to install the base system into your mount point<br />
`pacstrap /mnt base base-devel`

Create a boot directory for the EFI partition<br />
`mkdir /mnt/boot`

Mount EFI patition on boot directory<br />
`mount /dev/sdx1 /mnt/boot`

Enter the system's partition<br />
`arch-chroot /mnt`

Install shell, editor and packages for wifi connection<br />
`pacman -S zsh vim iw dialog wpa_supplicant`

Create a password to the root user<br />
`passwd`

Create a user<br />
`useradd -mg users -G wheel -s /bin/zsh your_user`

Change your user password<br />
`passwd your_user`

Enable wheel group<br />
`visudo`

Set language by unncomenting your it on locale.gen<br />
`vim /etc/locale.gen`

Create the locale file and config language<br />
`locale-gen`
`echo LANG=en_US.UTF-8 > /etc/locale.conf`
`export LANG=en_US.UTF-8`

Create a link between the timezone file and localtime file and set hwclock to store UTC<br />
`ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime`<br />
`hwclock --systohc --utc`

Choose your hostname<br />
`echo hostname > /etc/hostname`

Install the bootloader (grub) and EFI manager<br />
`pacman -S grub efibootmgr`

Install grub for the given architecture and EFI directory<br />
`grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=GRUB --recheck`

Generate an init file which grub uses to load linux<br />
`mkinitcpio -p linux`

Create the grub configuration file<br />
`grub-mkconfig -o /boot/grub/grub.cfg`

Disconnect from chroot session<br />
`exit`

Generate fstab file based on the hard drive<br />
`genfstab /mnt >> /mnt/etc/fstab`

Unmount the hard drive but unmount everything mounted on top of it, as the boot
directory<br />
`umount /mnt/boot`<br />
`umount /mnt`

Now reboot the system and check if everything is working.
