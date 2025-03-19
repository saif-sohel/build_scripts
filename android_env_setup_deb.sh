#!/usr/bin/env bash

# Copyright (C) 2018 Harsh 'MSF Jarvis' Shandilya
# Copyright (C) 2018 Akhil Narang
# SPDX-License-Identifier: GPL-3.0-only

# Script to setup an Android Build environment on Ubuntu 22.04 and later

LATEST_MAKE_VERSION="4.4"

# Get distribution info from os-release
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_NAME="$NAME"
    DISTRO_VERSION="$VERSION_ID"
else
    echo "Cannot detect OS version, trying to install anyway..."
    DISTRO_NAME="Unknown"
    DISTRO_VERSION="Unknown"
fi

echo "Detected: $DISTRO_NAME $DISTRO_VERSION"

echo "Installing main build packages for Android 15..."
sudo DEBIAN_FRONTEND=noninteractive \
    apt install \
    adb autoconf automake bc bison build-essential \
    ccache clang cmake curl fastboot flex g++ \
    g++-multilib gawk gcc gcc-multilib git git-lfs gnupg gperf \
    imagemagick lib32z1-dev libc6-dev libcap-dev \
    libexpat1-dev libgmp-dev liblz4-dev liblzma-dev libmpc-dev libmpfr-dev \
    libsdl2-dev libssl-dev libtool libxml2 libxml2-utils lzop \
    maven patch patchelf pkg-config python3-pyelftools python3-dev \
    python3-pip python3-pexpect python-is-python3 re2c schedtool \
    squashfs-tools subversion texinfo unzip xsltproc zip zlib1g-dev \
    libxml-simple-perl apt-utils rsync -y

# Install 32-bit libraries
echo "Installing 32-bit libraries..."
sudo apt install lib32ncurses-dev -y

# Install libncurses5 and libtinfo5 based on Ubuntu version
echo "Installing libncurses5 and libtinfo5..."
if ! dpkg -l | grep -q libncurses5; then
    # For Ubuntu 24.04+ where these packages are not in standard repos
    if [[ "${DISTRO_NAME}" == *"Ubuntu"* ]] && (( $(echo "${DISTRO_VERSION} >= 24.04" | bc -l) )); then
        echo "Ubuntu 24.04+ detected. Installing libncurses5 and libtinfo5 from older Ubuntu packages..."
        
        echo "Downloading and installing libtinfo5..."
        wget https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2_amd64.deb -q --show-progress
        sudo dpkg -i libtinfo5_6.3-2_amd64.deb
        rm -f libtinfo5_6.3-2_amd64.deb
        
        echo "Downloading and installing libncurses5..."
        wget https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncurses5_6.3-2_amd64.deb -q --show-progress
        sudo dpkg -i libncurses5_6.3-2_amd64.deb
        rm -f libncurses5_6.3-2_amd64.deb
        
        echo "libncurses5 and libtinfo5 installed successfully from older Ubuntu packages!"
    else
        # For Ubuntu 22.04 and earlier where these packages can be installed directly
        echo "Ubuntu 22.04 or earlier detected. Installing libncurses5 from repositories..."
        sudo apt install -y libncurses5 libtinfo5 || {
            echo "Could not install from repositories, falling back to manual installation..."
            
            echo "Downloading and installing libtinfo5..."
            wget https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2_amd64.deb -q --show-progress
            sudo dpkg -i libtinfo5_6.3-2_amd64.deb
            rm -f libtinfo5_6.3-2_amd64.deb
            
            echo "Downloading and installing libncurses5..."
            wget https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncurses5_6.3-2_amd64.deb -q --show-progress
            sudo dpkg -i libncurses5_6.3-2_amd64.deb
            rm -f libncurses5_6.3-2_amd64.deb
        }
    fi
else
    echo "libncurses5 is already installed"
fi

# Install libtinfo6 (used by newer tools)
sudo apt install libtinfo6 -y

echo "Installing GitHub CLI"
if ! command -v gh &> /dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
fi

echo "Setting up udev rules for adb!"
sudo curl --create-dirs -L -o /etc/udev/rules.d/51-android.rules https://raw.githubusercontent.com/M0Rf30/android-udev-rules/master/51-android.rules
sudo chmod 644 /etc/udev/rules.d/51-android.rules
sudo chown root /etc/udev/rules.d/51-android.rules
sudo systemctl restart udev

# Check make version and provide instructions if a different version is needed
if command -v make &> /dev/null; then
    makeversion="$(make -v | head -1 | awk '{print $3}')"
    if [[ ${makeversion} != "${LATEST_MAKE_VERSION}" ]]; then
        echo "Current make version is ${makeversion}, recommended version is ${LATEST_MAKE_VERSION}"
        echo "To install make ${LATEST_MAKE_VERSION}, you may need to download and compile it manually:"
        echo "1. wget https://ftp.gnu.org/gnu/make/make-${LATEST_MAKE_VERSION}.tar.gz"
        echo "2. tar xvf make-${LATEST_MAKE_VERSION}.tar.gz"
        echo "3. cd make-${LATEST_MAKE_VERSION}"
        echo "4. ./configure"
        echo "5. make"
        echo "6. sudo make install"
    fi
fi

echo "Installing repo"
sudo curl --create-dirs -L -o /usr/local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo
sudo chmod a+rx /usr/local/bin/repo

# Clean up deadsnakes PPA if it exists but doesn't support this Ubuntu version
if ls /etc/apt/sources.list.d/deadsnakes*.list >/dev/null 2>&1; then
    echo "Removing incompatible deadsnakes PPA"
    sudo rm /etc/apt/sources.list.d/deadsnakes*.list
    sudo apt update
fi


if [[ "${DISTRO_NAME}" == *"Ubuntu"* ]] && (( $(echo "${DISTRO_VERSION} >= 24.04" | bc -l) )); then
    echo "Your distro is Ubuntu 24.04 or later, you may face issues with nsjail"
    echo "To fix nsjail error follow the guide from below github gist:"
    echo "https://gist.github.com/saif-sohel/c86ea0a6af8cee38c8bfda6be3d1bc3d"

fi


# Suggest autoremove for unnecessary packages
echo "You may want to run 'sudo apt autoremove' to remove unnecessary packages"

echo -e "\nAOSP build environment setup complete!"
