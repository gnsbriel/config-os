<details>
<summary>Versão em Português 🇧🇷 (Clique Aqui)</summary>

:

</details>

<details open>
<summary>English Version 🇺🇸</summary>

# Config - OSa

Config - OS is a bash script and a collection of files used to quickly setup a brand new installation of Windows, Windows Subsystem for Linux, Linux (Ubuntu bases distros) and Arch Linux. This script, files and informations were created or edited with the sole intention of my own use but feel free to use them in any way !

- [Config - OSa](#config---osa)
  - [Arch Linux](#arch-linux)
    - [Optional Steps](#optional-steps)
    - [Partitioning](#partitioning)
    - [Formating](#formating)
    - [Mounting](#mounting)
    - [Mirrors](#mirrors)
    - [Pacstrap](#pacstrap)
    - [Generating fstab](#generating-fstab)
    - [Chroot into the system](#chroot-into-the-system)
    - [Configuring the System](#configuring-the-system)
  - [Linux (Ubuntu Based Distros)](#linux-ubuntu-based-distros)
  - [WSL - Windows Subsystem for Linux](#wsl---windows-subsystem-for-linux)
  - [Windows](#windows)

## Arch Linux

### Optional Steps

Configure System Clock and Keyboard Layout:

```
$ timedatectl set-ntp true
$ loadkeys us-acentos
```

### Partitioning

List Available Drivers:

```
$ fdisk -l
```

Create four partitions with `$ fdisk`, "root", "efi", "swap" and "home"

```
$ fdisk /dev/**DISK**
```

Size and file system for each partition:

```
/           +112690M                # Linux filesystem
/boot/efi   +807M                   # EFI System
[SWAP]      +16434M                 # Linux Swap
/home       Remainder of the device # Linux filesystem
```

### Formating

```
$ mkfs.ext4 -L ROOT /dev/root_partition
$ mkfs.fat -n BOOT-EFI -F 32 /dev/efi_system_partition
$ mkswap -L SWAP /dev/swap_partition
$ mkfs.ext4 -L HOME /dev/home_partition
```

### Mounting

```
$ mount /dev/root_partition /mnt
$ mkdir --parents /mnt/boot/efi
$ mkdir /mnt/home
$ mount /dev/efi_system_partition /mnt/boot/efi
$ swapon /dev/swap_partition
$ mount /dev/home_partition /mnt/home
```

### Mirrors

Download an up-to-date mirrorlist available at [Arch Linux Website](https://archlinux.org/mirrorlist/all/) containing all currently active mirrors. This file will later be copied to the new system by pacstrap so it's worth getting it ready now.


```
$ curl --location https://archlinux.org/mirrorlist/all/ --output /etc/pacman.d/mirrorlist
```

To enable mirrors, edit `/etc/pacman.d/mirrorlist` and locate your geographic region. Uncomment mirrors you would like to use.


For example:

```
## Worldwide
#Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
#Server = http://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
```

### Pacstrap

```
$ pacstrap -K /mnt base base-devel linux linux-firmware linux-firmware-qlogic sof-firmware nano dhcpcd git
```
### Generating fstab

```
$ genfstab -L /mnt >> /mnt/etc/fstab
```

### Chroot into the system

```
$ arch-chroot /mnt
```

### Configuring the System

Either use the file "./install" for an automated configuration, or follow the steps in the [Arch Wiki](https://wiki.archlinux.org/title/Installation_guide).

>Syntax: `$ ./install.sh [OPTION..] [MODIFIER..]`
>
>Options:
>
> -h, --help Print this help message.
>
> -a, --arch Current operational system (Arch Linux).
>
> -u, --ubuntu Current operational system (Ubuntu-based Distro).
>
> -wsl, --wsl Current operational system (Windows Subsystem for Linux).
>
> -w, --windows Current operational system (Windows).
>
>Modifiers:
>
> -c, --config-sys Configure system.
>
> -i, --install-packages Install packages.
>
> -p, --check-packages Check if all packages are installed (not available for -w, --windows).

## Linux (Ubuntu Based Distros)

Use the file "./install" for an automated configuration.

>Syntax: `$ ./install.sh [OPTION..] [MODIFIER..]`
>
>Options:
>
> -h, --help Print this help message.
>
> -a, --arch Current operational system (Arch Linux).
>
> -u, --ubuntu Current operational system (Ubuntu-based Distro).
>
> -wsl, --wsl Current operational system (Windows Subsystem for Linux).
>
> -w, --windows Current operational system (Windows).
>
>Modifiers:
>
> -c, --config-sys Configure system.
>
> -i, --install-packages Install packages.
>
> -p, --check-packages Check if all packages are installed (not available for -w, --windows).

## WSL - Windows Subsystem for Linux

Use the file "./install" for an automated configuration.

>Syntax: `$ ./install.sh [OPTION..] [MODIFIER..]`
>
>Options:
>
> -h, --help Print this help message.
>
> -a, --arch Current operational system (Arch Linux).
>
> -u, --ubuntu Current operational system (Ubuntu-based Distro).
>
> -wsl, --wsl Current operational system (Windows Subsystem for Linux).
>
> -w, --windows Current operational system (Windows).
>
>Modifiers:
>
> -c, --config-sys Configure system.
>
> -i, --install-packages Install packages.
>
> -p, --check-packages Check if all packages are installed (not available for -w, --windows).

## Windows

Use the file "./install" for an automated configuration.

>Syntax: `$ ./install.sh [OPTION..] [MODIFIER..]`
>
>Options:
>
> -h, --help Print this help message.
>
> -a, --arch Current operational system (Arch Linux).
>
> -u, --ubuntu Current operational system (Ubuntu-based Distro).
>
> -wsl, --wsl Current operational system (Windows Subsystem for Linux).
>
> -w, --windows Current operational system (Windows).
>
>Modifiers:
>
> -c, --config-sys Configure system.
>
> -i, --install-packages Install packages.
>
> -p, --check-packages Check if all packages are installed (not available for -w, --windows).

</details>
