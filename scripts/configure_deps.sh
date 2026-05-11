#!/usr/bin/env sh

set -e

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
spicetify apply -n

ollama run hf.co/unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF:Q4_K_M

rclone config

warp-cli registration new
warp-cli mode warp
warp-cli connect
