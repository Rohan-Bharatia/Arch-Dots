# Arch-Dots

![Arch Linux Logo](https://raw.githubusercontent.com/Rohan-Bharatia/Arch-Dots/refs/heads/main/assets/archlinux-logo.png)

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
| Timezone | US/Eastern |
| Automatic Time Sync (NTP) | Enabled |

6. Reboot and remove the external boot device (USB drive) while the screen is black

### Post-Install Configuration

1. Clone the git repository and travel to the specified directory (```$HOME/Arch-Dots``` by default).

2. Run the [```install_deps.sh```](./install_deps.sh) file to install or update all the listed dependencies.
> [!NOTE]
> Run the install script with the `--wpilib` tag to install all linux compatible FRC 2025 WPILib tools

3. Run the [```copy_dotfiles.sh```](./copy_dotfiles.sh) file to run the dotfiles from the repository directory to the ```~/.config/``` directory.

4. Enjoy! :)

> [!NOTE]
> You will need to reboot your system to see many changes made in the last step

## Gallery

![01](https://raw.githubusercontent.com/Rohan-Bharatia/Arch-Dots/refs/heads/main/assets/screenshots/01.png)

