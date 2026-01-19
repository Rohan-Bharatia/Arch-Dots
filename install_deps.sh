#!/bin/bash

set -euo pipefail

cd $HOME

sudo pacman -Syu
sudo pacman -S --needed --noconfirm base-devel gcc hyprland hyprpaper hyprlock hypridle hyprshot hyprsunset waybar kitty rofi nemo btop pipewire playerctl gtk3 git pavucontrol rclone python python-pip ttf-dejavu fastfetch openresolv fzf nvim matugen uwsm cava fontconfig swaync swayosd xsettingsd yazi zathura cmake meson cpio swww brightnessctl yad gnome-clocks nodejs npm imagemagick gum xorg-xhost gnome-keyring libsecret starship vlc mpv libva-utils unzip rust uv clang ffmpeg wl-clipboard mbuffer less nvidia-smi sentencepiece discord

if ! command -v yay >/dev/null; then
    mkdir -p $HOME/tmp
    cd $HOME/tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd $HOME
fi

yay -S --needed --noconfirm nerd-fonts blueman zen-browser-bin hblock waypaper wifitui hyprshade tray-tui spotify spicetify-cli cuda-12.5 cudnn9.3-cuda12.5

mkdir -p $HOME/.uv
cd $HOME/.uv
uv venv kokoros_cpu
source kokoros_cpu/bin/activate
cd kokoros_cpu
git clone https://github.com/lucasjinreal/Kokoros.git
cd Kokoros
uv pip install torch --index-url https://download.pytorch.org/whl/cpu
uv pip install -r scripts/requirements.txt
cargo build --release
chmod u+x scripts/*.sh
./scripts/download_models.sh
./scripts/download_voices.sh
ln -nfs $HOME/.uv/kokoros_cpu/Kokoros/target/release/koko $HOME/.local/bin/kokoros
cd $HOME/.uv
uv venv kokoros_gpu
source kokoros_gpu/bin/activate
cd kokoros_gpu
uv init -p 3.13
uv add kokoro-onnx soundfile
uv pip install onnxruntime-gpu sounddevice
uv run python -m ensurepip --upgrade
uv run python -m pip install --upgrade pip setuptools wheel
curl --retry 3 --retry-delay 2 -L -f -# -o kokoro-v1.0.fp16-gpu.onnx https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.fp16-gpu.onnx
curl --retry 3 --retry-delay 2 -L -f -# -o voices-v1.0.bin https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin
cd $HOME/.uv
uv venv parakeet_gpu
source parakeet_gpu/bin/activate
cd parakeet_gpu
uv pip install -U "nemo_toolkit[asr]"
uv pip install "numpy<2.4" --force-reinstall
uv pip install Flask
cat << 'EOF' > modeldownload.py
import torch
import nemo.collections.asr as nemo_asr
import gc
import sys
sys.stdout.reconfigure(line_buffering=True)
print("----------------------------------------------------------------")
print("   Starting Parakeet Model Download & Optimization Protocol")
print("----------------------------------------------------------------")
print("⏳ Loading model to CPU (bypassing VRAM limits)...")
try:
    asr_model = nemo_asr.models.ASRModel.from_pretrained(
        model_name="nvidia/parakeet-tdt-0.6b-v2",
        map_location=torch.device("cpu")
    )
except Exception as e:
    print(f"❌ Error loading model: {e}")
    sys.exit(1)
print("📉 Converting to Half Precision (FP16) to save VRAM...")
asr_model = asr_model.half()
print("🧹 Cleaning up system memory...")
gc.collect()
torch.cuda.empty_cache()
print("🚀 Moving model to GPU...")
try:
    asr_model = asr_model.cuda()
    print("✅ Success! Model is on GPU and ready for inference.")
except torch.cuda.OutOfMemoryError:
    print("❌ Out of Memory Error.")
    print("   Please close other GPU-heavy apps (browsers, games) and try again.")
    sys.exit(1)
except Exception as e:
    print(f"❌ Unexpected error moving to GPU: {e}")
    sys.exit(1)
print("----------------------------------------------------------------")
print("   Setup Complete.")
print("----------------------------------------------------------------")
EOF
python modeldownload.py
cd $HOME

hyprpm update
hyprpm add https://github.com/hyprwm/hyprland-plugins

if ! command -v ollama >/dev/null; then
    cd $HOME
    curl -fsSL https://ollama.com/install.sh | sh
fi

sudo chown -R $USER:$USER /opt/spotify
spicetify
spicetify backup apply enable-devtools
spicetify config current_theme Comfy color_scheme Comfy
spicetify config extensions fullAppDisplay.js
spicetify config extensions keyboardShortcut.js
spicetify config extensions shuffle+.js
spicetify config extensions popupLyrics.js
spicetify config extensions autoSkipVideo.js
spicetify apply -n

ollama pull phi3:mini
rclone config

for "$arg" in "$@"; do
    case "$arg" in
        --wpilib)
            local url="https://packages.wpilib.workers.dev/installer/v2025.3.2/Linux/WPILib_Linux-2025.3.2.tar.gz"
            local tar="$HOME/WPILib_Linux-2025.3.2.tar.gz"
            local dir="$HOME/WPILib_Linux-2025.3.2"
            curl -L "$url" -o "$tar"
            tar -xzf "$tar"
            cd "$dir"
            ./WPILibInstaller
            cd "$HOME"
            ;;
        *)
            ;;
    esac
done
