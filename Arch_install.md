Try in Virtual Machine First -

# Arch Linux — Fresh Installation Guide

**UEFI · GPT · Btrfs (`@`, `@home`) · systemd-boot + UKI · GNOME**

- **Target drive:** ` /dev/nvme0n1 ` (1 TB NVMe)
- **Timezone:** ` Asia/Kolkata `
- **Locale:** ` en_US.UTF-8 `
- **Keyboard:** US

> [!CAUTION]
> **Data loss:** partitioning and formatting erase the selected drive. Verify its size and model and ensure it is not the installer USB.

## Final partition layout

| Partition | Format and mount |

 /dev/nvme0n1p1  — 1 GiB, FAT32 EFI System Partition, mounted at  "/boot" 
 
 /dev/nvme0n1p2  — remaining space,  @  mounted at "/" and @home  mounted at  "/home" 

## Boot design: systemd-boot + UKI

mkinitcpio, creates a Unified Kernel Image (UKI) containing the kernel, initramfs, and embedded kernel command line. systemd-boot discovers UKIs in /EFI/Linux/ on the EFI partition. This setup does **not** require a manual boot entry that separately loads the kernel and initramfs.

---

## 1. Boot the ISO and verify

Boot the Arch ISO in **UEFI mode**.

```

ls /sys/firmware/efi/efivars

lsblk -o NAME,SIZE,MODEL,TYPE,FSTYPE,MOUNTPOINTS

ping -c 3 archlinux.org

timedatectl

```

- If  /sys/firmware/efi/efivars  is missing, reboot the USB in UEFI mode.
- Verify the 1 TB NVMe by size and model.
- If the ping fails on Wi-Fi, connect using iwctl and try again.

## 2. Create GPT partitions

Open  fdisk :

```

fdisk /dev/nvme0n1

```

Enter the following at the fdisk prompts, one at a time:

| Input | Action |
|---|---|
| `g` | Create a GPT partition table. |
| `n` | Create partition 1; accept the default partition number and first sector; enter `+1G` for the last sector. |
| `t` | Set partition 1 to **EFI System** (type code is usually `1`). |
| `n` | Create partition 2; accept the defaults through the final sector to use the remaining space. |
| `w` | Write changes and exit. |

Verify the layout:

```bash

lsblk -o NAME,SIZE,TYPE,FSTYPE /dev/nvme0n1

```

Confirm ` nvme0n1p1 ` is about 1 GiB and ` nvme0n1p2 ` uses the remaining space. Stop if the layout differs.

## 3. Format, create subvolumes, and mount

> [!CAUTION]
> These formatting commands destroy existing filesystems on the selected partitions.

### Format the partitions

```

mkfs.fat -F 32 -n EFI /dev/nvme0n1p1

mkfs.btrfs -f -L archroot /dev/nvme0n1p2

```

### Create Btrfs subvolumes

```

mount /dev/nvme0n1p2 /mnt

btrfs subvolume create /mnt/@

btrfs subvolume create /mnt/@home

umount /mnt

```

### Mount root, home, and EFI

```

mount -o noatime,compress=zstd,subvol=@ /dev/nvme0n1p2 /mnt

mkdir -p /mnt/home /mnt/boot

mount -o noatime,compress=zstd,subvol=@home /dev/nvme0n1p2 /mnt/home

mount /dev/nvme0n1p1 /mnt/boot

findmnt -R /mnt

btrfs subvolume list /mnt

```

This layout uses zram instead of a separate swap partition.

## 4. Install packages

Run this from the live ISO. If ` pacstrap ` reports an unavailable package, resolve the issue before continuing.

```

  pacstrap -K /mnt \
  base linux-firmware linux-lts amd-ucode mkinitcpio sudo base-devel efibootmgr \
  zram-generator networkmanager wpa_supplicant network-manager-applet \
  bluez bluez-utils pipewire pipewire-alsa pipewire-jack pipewire-pulse \
  gst-plugin-pipewire libpulse wireplumber \
  noto-fonts-emoji ttf-liberation ttf-dejavu \
  mesa xf86-video-amdgpu xf86-video-ati \
  libva-intel-driver intel-media-driver vpl-gpu-rt libvpl \
  vulkan-radeon vulkan-intel \
  nano openssh wget smartmontools xdg-utils \
  gnome gnome-tweaks gdm \
  amberol blanket btop extension-manager file-roller firefox fish git iotas \
  lm_sensors mpv resources ripgrep rsync helix zed code 7zip transmission-gtk

```

## 5. Generate `fstab` and enter the installed system

```

genfstab -U /mnt >> /mnt/etc/fstab

cat /mnt/etc/fstab

arch-chroot /mnt

```

Check that ` fstab ` contains root, home, and EFI entries. The Btrfs entries should use ` subvol=@ ` and ` subvol=@home `.

> From this point onward, commands run inside the installed system until you exit the chroot.

## 6. Configure locale, timezone, hostname, and user

### Timezone and clock

```

ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime

hwclock --systohc

```

### Locale

```

nano /etc/locale.gen

```

Uncomment this line, save, and exit:

```

en_US.UTF-8 UTF-8

```

Then run:

```

locale-gen

echo 'LANG=en_US.UTF-8' > /etc/locale.conf

echo 'KEYMAP=us' > /etc/vconsole.conf

```

### Hostname and hosts file

```

echo 'arch' > /etc/hostname

nano /etc/hosts

```

Set ` /etc/hosts ` to:

```

127.0.0.1   localhost
::1         localhost
127.0.1.1   arch.localdomain arch

```

# Create user and set password

    useradd -m -G wheel -s /usr/bin/fish gtz
    passwd gtz

# Enable sudo for wheel users

    EDITOR=nano visudo 
    
Uncomment #

    %wheel ALL=(ALL:ALL) ALL

# Lock root password

    passwd -l root


## 7. Configure UKI generation

### Set the embedded kernel command line

Get the UUID of the Btrfs partition:

```

blkid -s UUID -o value /dev/nvme0n1p2

nano /etc/kernel/cmdline

```

Put the following on one line, replacing the placeholder with the actual UUID:

```

root=UUID=REPLACE_WITH_BTRFS_UUID rootflags=subvol=@ rw

```

**Do not leave the placeholder in the file.** The UUID must match the Btrfs partition.

### Configure the `linux-lts` mkinitcpio preset

Edit the existing preset:

```

nano /etc/mkinitcpio.d/linux-lts.preset

```

Preserve unrelated settings and ensure these settings are active, without duplicate definitions:

```

ALL_kver="/boot/vmlinuz-linux-lts"
ALL_cmdline="/etc/kernel/cmdline"

PRESETS=('default' 'fallback')

default_image="/boot/initramfs-linux-lts.img"
default_uki="/boot/EFI/Linux/arch-linux-lts.efi"
default_options=""

fallback_image="/boot/initramfs-linux-lts-fallback.img"
fallback_uki="/boot/EFI/Linux/arch-linux-lts-fallback.efi"
fallback_options="-S autodetect"

```

Build and inspect the UKIs:

```

mkdir -p /boot/EFI/Linux

mkinitcpio -P

ls -lh /boot/EFI/Linux/

```

Expected files include:

- ` /boot/EFI/Linux/arch-linux-lts.efi `
- ` /boot/EFI/Linux/arch-linux-lts-fallback.efi ` (if the fallback preset builds successfully)

Fix any ` mkinitcpio ` errors before rebooting. The microcode hook includes AMD microcode in the UKI; do not add a separate ` amd-ucode ` initrd line to a UKI boot entry.

## 8. Install and configure systemd-boot

Install the bootloader:

```

bootctl install

mkdir -p /boot/loader

nano /boot/loader/loader.conf

```

Use this `loader.conf`:

```

default arch-linux-lts.efi
timeout 3
console-mode max
editor no

```

` systemd-boot ` discovers UKIs in ` /boot/EFI/Linux/ `. Do **not** create a manual ` arch.conf ` entry for a separate kernel and initramfs.

Check the bootloader and command line:

```

bootctl status

bootctl list

cat /etc/kernel/cmdline

```

## 9. Configure zram and enable services

Create the zram configuration:

```

nano /etc/systemd/zram-generator.conf

```

Enter:

```

[zram0]
zram-size = ram / 2
compression-algorithm = zstd

```

Enable services:

```

systemctl enable NetworkManager
systemctl enable gdm
systemctl enable bluetooth
systemctl enable systemd-timesyncd
systemctl enable fstrim.timer

```

## 10. Verify, exit, and reboot

Run the checks below before rebooting:

```

pacman -Q linux-lts gnome gdm networkmanager mkinitcpio

findmnt /boot

findmnt /

findmnt /home

cat /etc/fstab

cat /etc/kernel/cmdline

blkid -s UUID -o value /dev/nvme0n1p2

ls -lh /boot/EFI/Linux/

bootctl status

bootctl list

```

Before rebooting, confirm:

- The UUID in ` /etc/kernel/cmdline ` matches the Btrfs partition UUID.
- The command line contains ` rootflags=subvol=@ `.
- The UKI files exist under ` /boot/EFI/Linux/ `.
- ` bootctl list ` shows the UKI.

Then exit the chroot, unmount, and reboot:

```

exit

umount -R /mnt

reboot

```

Remove the installer USB during restart. If needed, select **Linux Boot Manager** for the NVMe drive in firmware. If unmounting reports a busy filesystem, investigate rather than forcing it.

## Pre-reboot checklist

- [ ] Booted the ISO in UEFI mode and verified the correct NVMe
- [ ] Created GPT, 1 GiB FAT32 EFI, and Btrfs root partitions
- [ ] Created and mounted @ and @home
- [ ] pacstrap completed without unresolved package errors
- [ ] Configured fstab, locale, timezone, hostname, user, and sudo
- [ ] Set the correct UUID and rootflags=subvol=@ in /etc/kernel/cmdline 
- [ ] mkinitcpio -P generated UKIs in /boot/EFI/Linux/
- [ ] Installed systemd-boot and set the default UKI filename.
- [ ] Enabled NetworkManager, GDM, Bluetooth, time synchronization, and fstrim.timer

## References

- [ArchWiki — Unified kernel image](https://wiki.archlinux.org/title/Unified_kernel_image)
- [ArchWiki — systemd-boot](https://wiki.archlinux.org/title/Systemd-boot_)
- [ArchWiki — Btrfs](https://wiki.archlinux.org/title/Btrfs)
- [ArchWiki — EFI system partition](https://wiki.archlinux.org/title/EFI_system_partition)
- [mkinitcpio manual](https://man.archlinux.org/man/core/mkinitcpio/mkinitcpio.8.en)
