# Arch-Dots

![Arch Linux Logo](./.github/assets/archlinux-logo.png)

Configuration files for my Arch Linux setup

## Installation & Setup Instructions

### Archinstall Configuration

1. Download a fresh copy of the latest Arch Linux version ISO files

2. Format the ISO file with a program like Rufus, Balena Etcher, Chromebook Recovery Utility, etc.

3. Plug the USB into the computer, enter the BIOS, turn off secure boot, and push the USB drive to the top of the boot order

4. Boot into the Arch Linux installation program, and run the following commands:

```sh
iwctl station wlan0 connect "{SSID}" # Not necessary if using ethernet
ping -c 6 google.com
systemctl enable --now sshd
passwd
archinstall
```

5. Inside of the `archinstall`, select the following options:

| Section | Selected Option(s) |
| - | - |
| Archinstall Language | English |
| Mirrors & Repositories | United States |
| Disk Configuration | Best effort default partition layout with btrfs |
| Swap | zstd compression |
| Bootloader | systemd |
| Kernels | Linux & Linux LTS |
| Profile | Hyprland, NVidia (proprietary), & ly |
| Applications | Bluetooth, Pipewire, CUPS, PPD |
| Network Configuration | Copy ISO configuration |
| Additional Packages | git |
| Timezone | America/New_York |
| Automatic Time Sync (NTP) | Enabled |

6. Reboot and remove the external boot device (USB drive) while the screen is black

### Post-Install Configuration

1. Clone the git repository and travel to the specified directory (```$HOME/Arch-Dots``` by default).

2. Run [`scripts/install_deps.sh`](./scripts/install_deps.sh) from the repository root directory.

3. Run [`scripts/configure_deps.sh`](./scripts/configure_deps.sh) from the repository root directory.

4. Run [`scripts/copy_dotfiles.sh`](./scripts/copy_dotfiles.sh) from the repository root directory.

5. Reboot and log in to see all changes.

> [!NOTE]
> Run the [`scripts/manage_wpilib_pkgs.sh`](./scripts/manage_wpilib_pkgs.sh) script to install all Linux-compatible WPILib 2026 tools.

## Gallery

