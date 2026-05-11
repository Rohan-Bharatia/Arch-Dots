#!/usr/bin/env sh

set -e

WPI_URL="https://packages.wpilib.workers.dev/installer/v2026.2.1/Linux/WPILib_Linux-2026.2.1.tar.gz"
WPI_TAR="$HOME/WPILib_Linux-2026.2.1.tar.gz"
WPI_DIR="$HOME/WPILib_Linux-2026.2.1"
sudo mkdir -p "/usr/share/icons/frc"
curl -L "$WPI_URL" -o "$WPI_TAR"
tar -xzf "$WPI_TAR"
./"$WPI_DIR"/WPILibInstaller
rm -rf "$WPI_TAR" "$WPI_DIR"

CHOR_URL="https://github.com/SleipnirGroup/Choreo/releases/download/v2026.0.3/Choreo-v2026.0.3-Linux-x86_64-standalone.zip"
CHOR_ZIP="$HOME/Choreo-v2026.0.3-Linux-x86_64-standalone.zip"
CHOR_DIR="$HOME/Choreo-v2026.0.3-Linux-x86_64-standalone"
CHOR_ICON_URL="https://raw.githubusercontent.com/SleipnirGroup/Choreo/refs/heads/main/src-tauri/icons/128x128.png"
CHOR_ICON="/usr/share/frc/choreo.png"
curl -L "$CHOR_URL" -o "$CHOR_ZIP"
sudo curl -L "$CHOR_ICON_URL" -o "$CHOR_ICON"
mkdir -p "$CHOR_DIR"
unzip -o "$CHOR_ZIP" -d "$CHOR_DIR"
sudo chmod +x ./"$CHOR_DIR"/*
sudo mv ./"$CHOR_DIR"/* /usr/local/bin/
rm -rf "$CHOR_ZIP" "$CHOR_DIR"
