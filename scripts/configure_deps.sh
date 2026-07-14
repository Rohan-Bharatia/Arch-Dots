#!/usr/bin/env sh

set -e

grep -q 'acpi_backlight=native' /etc/default/grub || sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\([^"]*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 acpi_backlight=native"/' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

git config --global credential.helper /usr/lib/git-core/git-credential-libsecret

if [ -e /usr/bin/zsh ]; then
    chsh -s $(which /usr/bin/zsh)
fi

sudo mkdir -p /opt/spotify
sudo chown -R $(whoami):$(whoami) /opt/spotify

spicetify backup apply enable-devtools
spicetify config current_theme matugen color_scheme matugen
spicetify config extensions fullAppDisplay.js
spicetify config extensions keyboardShortcut.js
spicetify config extensions shuffle+.js
spicetify config extensions popupLyrics.js
spicetify config extensions autoSkipVideo.js
spicetify config custom_apps lyrics-plus
spicetify apply -n

ollama run hf.co/unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF:Q4_K_M

yabridgectl add ~/.wine/drive_c
yabridgectl sync

# TODO: Ensure `/etc/fuse.conf` has `user_allow_other` enabled

rclone config

warp-cli registration new
warp-cli mode warp
warp-cli connect
