#!/bin/bash

STARTDIR=$PWD

# Update and upgrade WSL if it's old
sudo apt update && sudo apt upgrade -y

# Install the necessary packages
sudo apt-get install build-essential git qemu-user libncurses-dev flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf liblz4-tool bc curl gcc git libssl-dev libncurses5-dev lzop make u-boot-tools libgmp3-dev libmpc-dev -y

# Get and unpack the ARM compiler tools for x64
wget -c https://developer.arm.com/-/media/Files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf.tar.xz
sudo tar xf gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf.tar.xz -C /opt

# Setup the PATH to reference the newly unpacked tools.
# IMPORTANT: This export is required for configure to pickup the ARM tools
# IMPORTANT: so the path must be exported like this. The update to .bashrc
# IMPORTANT: is purely for convenience later if you decide to run the tools
echo 'export PATH=/opt/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf/bin:$PATH' >> ~/.bashrc
export PATH=/opt/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf/bin:$PATH

# Update symbolic links to reference the ARM libraries needed for the build
sudo ln -s /opt/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf/arm-none-linux-gnueabihf/libc/lib/ld-linux-armhf.so.3 /lib/ld-linux-armhf.so.3
sudo ln -s /opt/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf/arm-none-linux-gnueabihf/libc/lib/libc.so.6 /lib/libc.so.6
sudo ln -s /opt/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf/arm-none-linux-gnueabihf/libc/lib/libpthread.so.0 /lib/libpthread.so.0

# Get latest version of CDRDAO
if [ ! -d "cdrdao-repo" ]; then
    git clone https://github.com/cdrdao/cdrdao.git cdrdao-repo
fi

# Go into the cdrdao-repo directory and configure the build to run for ARM Linux
cd cdrdao-repo
git checkout master
git pull
autoreconf -fi
./configure --host=arm-none-linux-gnueabihf
make all

# Fetch and package the two necessary binaries
cp ./dao/cdrdao $STARTDIR
cp ./utils/toc2cue $STARTDIR
cd $STARTDIR
tar cvfz ./mister-cdrdao.tar.gz ./cdrdao ./toc2cue
