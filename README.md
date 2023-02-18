<details>
<summary>Versão em Português 🇧🇷 (Clique Aqui)</summary>

:

</details>

<details open>
<summary>English Version 🇺🇸</summary>

# Config - OS

Config - OS is a bash script and a collection of files used to quickly setup a brand new installation of Windows, Windows Subsystem for Linux and mainly, Arch Linux. This script, files and informations were created or edited with the sole intention of my own use but feel free to use them in any way !

- [Config - OS](#config---os)
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
  - [WSL - Windows Subsystem for Linux](#wsl---windows-subsystem-for-linux)
  - [Windows](#windows)

## Arch Linux

### Optional Steps

Configure System Clock and Keyboard Layout:

```bash
#!/bin/bash

$ timedatectl set-ntp true
$ loadkeys us-acentos
```

### Partitioning

List Available Drivers:

```bash
#!/bin/bash

$ fdisk -l
```

Create four partitions with `$ fdisk`, "root", "efi", "swap" and "home"

```bash
#!/bin/bash

$ fdisk /dev/**DISK**
```

Size and file system for each partition:

```text
/           +112690M                # Linux filesystem
/boot/efi   +807M                   # EFI System
[SWAP]      +16434M                 # Linux Swap
/home       Remainder of the device # Linux filesystem
```

### Formating

```bash
#!/bin/bash

$ mkfs.ext4 -L ROOT /dev/root_partition
$ mkfs.fat -n BOOT-EFI -F 32 /dev/efi_system_partition
$ mkswap -L SWAP /dev/swap_partition
$ mkfs.ext4 -L HOME /dev/home_partition
```

### Mounting

```bash
#!/bin/bash

$ mount /dev/root_partition /mnt
$ mkdir --parents /mnt/boot/efi
$ mkdir /mnt/home
$ mount /dev/efi_system_partition /mnt/boot/efi
$ swapon /dev/swap_partition
$ mount /dev/home_partition /mnt/home
```

### Mirrors

Download an up-to-date mirrorlist available at [Arch Linux Website](https://archlinux.org/mirrorlist/all/) containing all currently active mirrors. This file will later be copied to the new system by pacstrap so it's worth getting it ready now.

```bash
#!/bin/bash

$ curl --location https://archlinux.org/mirrorlist/all/ --output /etc/pacman.d/mirrorlist
```

To enable mirrors, edit `/etc/pacman.d/mirrorlist` and locate your geographic region. Uncomment mirrors you would like to use.

For example:

```text
## Worldwide
#Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
#Server = http://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
```
Or you can use a tool like `Reflector` to automate this process.

### Pacstrap

```bash
#!/bin/bash

$ pacstrap -K /mnt base base-devel linux linux-firmware linux-firmware-qlogic sof-firmware nano dhcpcd git
```

### Generating fstab

```bash
#!/bin/bash

$ genfstab -L /mnt >> /mnt/etc/fstab
```

### Chroot into the system

```bash
#!/bin/bash

$ arch-chroot /mnt
```

### Configuring the System

Either use the file "./install" for an automated configuration, or follow the steps in the [Arch Wiki](https://wiki.archlinux.org/title/Installation_guide).

>Try: `$ ./install.sh --help` for more information.

## WSL - Windows Subsystem for Linux

Use the file "./install" for an automated configuration.

>Try: `$ ./install.sh --help` for more information.

## Windows

Use the file "./install" for an automated configuration.

>Try: `$ ./install.sh --help` for more information.

</details>
