#!/bin/bash

# Fedora Post Installation Script

# This script automates the setup of Fedora after a fresh installation.
# It includes updating the system, enabling repositories, installing codecs,
# configuring hardware acceleration, setting hostname, and installing common applications.

# Make sure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo or as root."
  exit
fi

# Faster Updates
echo "Configuring DNF for faster updates..."
sudo cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak
sudo tee /etc/dnf/dnf.conf > /dev/null << EOF
[main]
gpgcheck=1
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
max_parallel_downloads=10
EOF

# RPM Fusion Repositories
echo "Enabling RPM Fusion repositories..."
sudo dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-\$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-\$(rpm -E %fedora).noarch.rpm

# Install app-stream metadata
echo "Updating core group to install app-stream metadata..."
sudo dnf group update core -y

# Update System
echo "Updating the system..."
sudo dnf -y update
sudo dnf -y upgrade --refresh

# Enable Flathub
echo "Adding Flathub repository..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Media Codecs
echo "Installing media codecs..."
sudo dnf swap 'ffmpeg-free' 'ffmpeg' --allowerasing -y
sudo dnf group install Multimedia -y
sudo dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
sudo dnf update @sound-and-video -y

# H/W Video Acceleration
echo "Installing hardware video acceleration packages..."
sudo dnf install ffmpeg ffmpeg-libs libva libva-utils -y

# Detect GPU and configure video acceleration accordingly
echo "Detecting GPU and configuring hardware acceleration..."

if lspci | grep -i 'vga' | grep -i 'intel' > /dev/null; then
    echo "Intel GPU detected."
    echo "Configuring Intel hardware acceleration..."
    sudo dnf swap libva-intel-driver intel-media-driver --allowerasing -y
elif lspci | grep -i 'vga' | grep -i 'amd' > /dev/null; then
    echo "AMD GPU detected."
    echo "Configuring AMD hardware acceleration..."
    sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
    sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y
else
    echo "No Intel or AMD GPU detected, or unable to determine GPU vendor."
fi

# OpenH264 for Firefox
echo "Installing OpenH264 codecs for Firefox..."
sudo dnf config-manager --set-enabled fedora-cisco-openh264
sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264
echo "Please enable the OpenH264 plugin in Firefox settings after the script completes."

# Set Hostname
echo -n "Enter the new hostname: "
read NEW_HOSTNAME
sudo hostnamectl set-hostname "$NEW_HOSTNAME"

# Install applications
echo "Installing applications..."

# Install Steam
echo "Installing Steam..."
sudo dnf install steam -y

echo "Installing GNOME Tweaks..."
sudo dnf install gnome-tweaks -y

sudo dnf install -y \
    vim \
    git \
    wget \
    curl \
    htop \
    gnome-tweaks \
    util-linux-user \
    zsh \

chsh -s $(which zsh)

# Install Flatpak applications
echo "Installing Flatpak applications..."
flatpak install flathub com.discordapp.Discord -y
flatpak install flathub md.obsidian.Obsidian -y
flatpak install flathub com.spotify.Client -y
flatpak install flathub org.mozilla.Thunderbird -y



echo "All tasks completed successfully."

