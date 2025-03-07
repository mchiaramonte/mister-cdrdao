#!/bin/bash

STARTDIR=$PWD

# Get and unpack the ARM compiler tools for x64
wget -q -c https://developer.arm.com/-/media/Files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf.tar.xz
sudo tar xf gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf.tar.xz -C /opt
rm gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf.tar.xz

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

# Get the latest version of binmerge
if [ ! -d "binmerge-repo" ]; then
    git clone https://github.com/putnam/binmerge.git binmerge-repo
fi

# Copy the latest version of binmerge for splitting the BIN/CUE files
cd binmerge-repo
git checkout main
git pull
cd $STARTDIR
mv -v ./binmerge-repo/binmerge $STARTDIR/Scripts/.config/mister-cdrdao

# Go into the cdrdao-repo directory and configure the build to run for ARM Linux
cd cdrdao-repo
git checkout master
git pull
./autogen.sh
./configure --host=arm-none-linux-gnueabihf
make all

mv -v \
  ./dao/cdrdao \
  ./utils/toc2cue  \
  $STARTDIR/Scripts/.config/mister-cdrdao

cd $STARTDIR
bash .github/getredumpdata.sh
cd $STARTDIR
mv -v *.dat $STARTDIR/Scripts/.config/mister-cdrdao
rm -rf binmerge-repo cdrdao-repo
find Scripts
