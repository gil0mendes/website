# Guix

## Introduction to GNU Guix

GNU Guix is a package manager and operating system distribution that follows the principles of free software. It is a project of the GNU project and was launched in 2012. GNU Guix provides a declarative approach to system configuration management and allows users to define and reproduce complete system configurations. It is written in the programming language Scheme and uses the GNU Shepherd as its init system.

## Guix Home

Guix Home is a user-friendly version of GNU Guix that is designed for personal use. It provides a simple interface to the Guix package manager and allows users to easily install and manage packages on their systems. Guix Home also includes pre-built binaries for popular software packages, making it easier to get started with the system. Despite its focus on ease-of-use, Guix Home still adheres to the principles of free software and provides users with complete control over their systems.

## Instalation Notes (not final)

### Formatting

I like to access via ssh into the machine to make it easy to copy command from my mac

```jsx
herd start sshd
# set a password for the root
passwd
```

On the mac side, I connect to it using the root user and the machine’s IP

```jsx
ssh root@192.18.1.16
```

start a shell with all the tools required

```jsx
guix shell lvm2 cryptsetup parted btrfs-progs git emacs
```

I like to use emacs for this to make it easy to work with scheme. To make it more usable enable the following modes:

- fido-vertical-mode
- electric-pair-mode

https://gist.github.com/Le0xFF/21942ab1a865f19f074f13072377126b

wipe the disk

```jsx
wipefs -a /dev/nvmme0n1
```

partition disk

```jsx
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart primary 1MiB 1GiB     # EFI partition
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 1GiB 100%     # LUKS encrypted partition
```

set up LUKS2

```jsx
cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 matrix
```

set up lvm

```jsx
pvcreate /dev/mapper/matrix
vgcreate matrix /dev/mapper/matrix
lvcreate -L 32G -n swap matrix
lvcreate -l 100%FREE -n system matrix
```

format partition

```jsx
mkfs.vfat -n EFI -F 32 /dev/nvme0n1p1
mkswap /dev/matrix/swap # UUID = 994be033-ab43-4f02-9ed7-71db92871354
mkfs.btrfs -L NixOS /dev/matrix/system # UUID = 1dd1f612-b675-4cc1-b836-2bd573e3f9b6
```

mount partitions

```jsx
export BTRFS_OPT=rw,noatime,discard=async,compress-force=zstd,space_cache=v2,commit=120
mount -o $BTRFS_OPT /dev/mapper/matrix-system /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@gnu
btrfs subvolume create /mnt/@guix-config

umount /mnt
mount -o $BTRFS_OPT,subvol=@ /dev/mapper/matrix-system /mnt/

mkdir /mnt/home
mkdir /mnt/gnu
mkdir -p /mnt/etc/
mkdir -p /mnt/var/log
mkdir -p /mnt/etc/system
mount -o $BTRFS_OPT,subvol=@home /dev/mapper/matrix-system /mnt/home/
mount -o $BTRFS_OPT,subvol=@gnu /dev/mapper/matrix-system /mnt/gnu/
mount -o $BTRFS_OPT,subvol=@guix-config /dev/mapper/matrix-system /mnt/etc/system/
mount -o $BTRFS_OPT,subvol=@log /dev/mapper/matrix-system /mnt/var/log

mkdir -p /mnt/boot/efi
mount -o rw,noatime /dev/nvme0n1p1 /mnt/boot/efi

swapon /dev/matrix/swap
```

create the configuration. To get the UUID of the luks use `cryptsetup luksUUID /dev/nvme0n1p2` 

This is the channels.scm file

```jsx
(cons* (channel
        (name 'nonguix)
        (url "https://gitlab.com/nonguix/nonguix")
        ;; Enable signature verification:
        (introduction
         (make-channel-introduction
          "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
          (openpgp-fingerprint
           "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
       %default-channels)
```

and this is the config.scm file

```jsx
(use-modules (gnu)
             (gnu system nss)
             (gnu system file-systems)
             (gnu system mapped-devices)
             (gnu system keyboard)
             (gnu services shepherd)
             (gnu services networking)
             (gnu services desktop)
             (gnu services ssh)
             (gnu packages certs)
             (gnu packages linux))

;; import nonfree linux module
(use-modules (nongnu packages linux)
             (nongnu system linux-initrd))

(use-service-modules desktop networking ssh xorg)

(define %luks-device
  (mapped-device
   (source (uuid "ab37a65a-7396-43a8-85da-782f1e5d9aa1"))
   (target "matrix")
   (type luks-device-mapping)))

(define %lvm-device
  (mapped-device
   (source "matrix")
   (target "matrix-system")
   (type lvm-device-mapping)))

(operating-system
 (host-name "eezo")
 (timezone "Europe/Lisbon")
 (locale "en_US.utf8")

 (keyboard-layout (keyboard-layout "us"))

 (initrd microcode-initrd)
 (initrd-modules (append (list "vmd" "dm_mod" "dm_crypt" "btrfs" "dm-snapshot" "i915" "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc") %base-initrd-modules))

 (users (cons* (user-account
                (name "gil0mendes")
                (comment "Gil")
                (group "users")
                (home-directory "/home/gil0mendes")
                (supplementary-groups '("wheel" "netdev" "audio" "video")))
                %base-user-accounts))

 (bootloader (bootloader-configuration
              (bootloader grub-efi-bootloader)
              (targets (list "/boot/efi"))
              (keyboard-layout keyboard-layout)))

 (mapped-devices (list %luks-device %lvm-device))

 (file-systems (append
    (list (file-system
            (device "/dev/mapper/matrix-system")
            (mount-point "/")
            (type "btrfs")
            (options "subvol=@,noatime")
            (dependencies mapped-devices))

          (file-system
            (device "/dev/mapper/matrix-system")
            (mount-point "/home")
            (type "btrfs")
            (options "subvol=@home,noatime"))

          (file-system
            (device "/dev/mapper/matrix-system")
            (mount-point "/gnu")
            (type "btrfs")
            (options "subvol=@gnu,noatime"))

          (file-system
            (device "/dev/mapper/matrix-system")
            (mount-point "/etc/system")
            (type "btrfs")
            (options "subvol=@guix-config,noatime"))

          (file-system
            (device "/dev/mapper/matrix-system")
            (mount-point "/var/log")
            (type "btrfs")
            (options "subvol=@log,noatime"))

          (file-system
            (device (uuid "994be033-ab43-4f02-9ed7-71db92871354"))
            (mount-point "/boot")
            (type "vfat")))

    %base-file-systems))

 (swap-devices (list (swap-space (target "/dev/mapper/matrix-swap"))))

 (services
  (append
   (list (service xfce-desktop-service-type)
         (service xorg-server-service-type)
;;       (service network-manager-service-type)
         (service dhcp-client-service-type))
   %base-services))

 (firmware (list linux-firmware))
 (kernel linux))
```

now this is for the installation phase:

```jsx
herd start cow-store /mnt
guix time-machine -C /mnt/etc/system/channels.scm -- system init /mnt/etc/system/config.scm /mnt/ --substitute-urls='https://ci.guix.gnu.org https://bordeaux.guix.gnu.org https://substitutes.nonguix.org' --fallback
```
