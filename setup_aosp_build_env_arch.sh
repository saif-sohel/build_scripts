#!/usr/bin/env bash

# SPDX-License-Identifier: GPL-3.0-only
# Author: Saif Sohel <github.com/saif-sohel>

# Script to setup an AOSP Build environment on Arch Linux and derivatives
# Will continue to be updated as needed due to Arch Linux's rolling release nature
# Adapted from Akhil Narang's Ubuntu/Debian script

echo "Setting up AOSP build environment for Arch Linux"

# Install base development packages
echo "Installing base development packages..."
sudo pacman -S --needed --noconfirm base-devel git gnupg ccache

# Install AOSP required packages
echo "Installing AOSP required packages..."
sudo pacman -S --needed --noconfirm \
    android-tools android-udev \
    autoconf automake axel bc bison \
    clang cmake curl expat flex \
    gawk gcc gcc-libs gperf \
    htop imagemagick lib32-ncurses lib32-zlib \
    libcap libexpat libmpc libmpfr ncurses \
    lz4 lzop \
    maven ncftp patch pngcrush \
    python python-virtualenv python2 \
    re2c rsync schedtool sdl squashfs-tools subversion \
    texinfo unzip w3m xsltproc zip zlib lzip \
    libxml2 ninja wget

# Install Java 11
echo "Installing Java 11..."
sudo pacman -S --needed --noconfirm jdk11-openjdk jre11-openjdk

# Set Java 11 as default
echo "Setting Java 11 as default..."
sudo archlinux-java set java-11-openjdk
java -version

# Install GitHub CLI
echo "Installing GitHub CLI..."
sudo pacman -S --needed --noconfirm github-cli

# Setup udev rules for adb
echo "Setting up udev rules for adb..."
sudo curl --create-dirs -L -o /etc/udev/rules.d/51-android.rules -O -L https://raw.githubusercontent.com/M0Rf30/android-udev-rules/master/51-android.rules
sudo chmod 644 /etc/udev/rules.d/51-android.rules
sudo chown root /etc/udev/rules.d/51-android.rules
sudo udevadm control --reload-rules

# Install repo tool
echo "Installing repo tool..."
sudo curl --create-dirs -L -o /usr/local/bin/repo -O -L https://storage.googleapis.com/git-repo-downloads/repo
sudo chmod a+rx /usr/local/bin/repo

# Setup file descriptor limits
echo "Setting up file descriptor limits..."
if ! grep -q "* soft nofile 8192" /etc/security/limits.conf; then
    echo "* soft nofile 8192" | sudo tee -a /etc/security/limits.conf
    echo "* hard nofile 16384" | sudo tee -a /etc/security/limits.conf
fi

# Setup ccache
echo "Setting up ccache..."
if ! grep -q "export USE_CCACHE=1" ~/.bashrc; then
    echo 'export USE_CCACHE=1' >> ~/.bashrc
    echo 'export CCACHE_EXEC=/usr/bin/ccache' >> ~/.bashrc
fi

# Set up Some AUR packages that might be needed (using yay)
echo "Checking if yay is installed for AUR packages..."
if ! command -v yay &> /dev/null; then
    echo "yay not found, installing..."
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi

# Install some useful AUR packages
echo "Installing useful AUR packages..."
yay -S --needed --noconfirm lib32-gcc-libs lineageos-devel

echo
echo "====================================================="
echo "AOSP build environment setup complete!"
echo
echo "Next step: Cook some delicious ROMs!"
echo "====================================================="