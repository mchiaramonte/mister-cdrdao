#!/bin/bash
set -euo pipefail

STARTDIR=$PWD

# Get and unpack the ARM compiler tools for x64
wget -q -c https://developer.arm.com/-/media/Files/downloads/gnu-a/${GCC_VERSION}/binrel/gcc-arm-${GCC_VERSION}-x86_64-arm-none-linux-gnueabihf.tar.xz
sudo tar xf gcc-arm-${GCC_VERSION}-x86_64-arm-none-linux-gnueabihf.tar.xz -C /opt
rm gcc-arm-${GCC_VERSION}-x86_64-arm-none-linux-gnueabihf.tar.xz

# Setup the PATH to reference the newly unpacked tools.
# IMPORTANT: This export is required for configure to pickup the ARM tools
# IMPORTANT: so the path must be exported like this.
export PATH=/opt/gcc-arm-${GCC_VERSION}-x86_64-arm-none-linux-gnueabihf/bin:$PATH

# Update symbolic links to reference the ARM libraries needed for the build
sudo ln -s /opt/gcc-arm-${GCC_VERSION}-x86_64-arm-none-linux-gnueabihf/arm-none-linux-gnueabihf/libc/lib/ld-linux-armhf.so.3 /lib/ld-linux-armhf.so.3
sudo ln -s /opt/gcc-arm-${GCC_VERSION}-x86_64-arm-none-linux-gnueabihf/arm-none-linux-gnueabihf/libc/lib/libc.so.6 /lib/libc.so.6
sudo ln -s /opt/gcc-arm-${GCC_VERSION}-x86_64-arm-none-linux-gnueabihf/arm-none-linux-gnueabihf/libc/lib/libpthread.so.0 /lib/libpthread.so.0

wget -q https://github.com/putnam/binmerge/releases/download/${BINMERGE_VERSION}/binmerge-${BINMERGE_VERSION}.zip
unzip binmerge-${BINMERGE_VERSION}.zip
mv -v binmerge-${BINMERGE_VERSION}/binmerge $STARTDIR/Scripts/.config/mister-cdrdao
rm -rf binmerge-${BINMERGE_VERSION} ${BINMERGE_VERSION}.zip

wget -q https://github.com/cdrdao/cdrdao/releases/download/${CDRDAO_RELEASE}/cdrdao-${CDRDAO_VERSION}.tar.bz2
tar xf cdrdao-${CDRDAO_VERSION}.tar.bz2

# Go into the cdrdao-repo directory and configure the build to run for ARM Linux
cd cdrdao-${CDRDAO_VERSION}
./configure --host=arm-none-linux-gnueabihf
make all

mv -v \
  ./dao/cdrdao \
  ./utils/toc2cue  \
  $STARTDIR/Scripts/.config/mister-cdrdao

cd $STARTDIR
rm -rf cdrdao-${CDRDAO_VERSION} cdrdao-${CDRDAO_VERSION}.tar.bz2

for target in PSX:psx Saturn:ss MegaCD:mcd TGFX16-CD:pce NeoGeo-CD:ngcd; do
  system=`echo $target | awk -F: '{print $1}'`
  url=`echo $target | awk -F: '{print $2}'`
  echo "==> Downloading ${system} dat file..."
  wget -q http://redump.org/datfile/${url}/ -O ${system}.zip
  unzip -p ${system}.zip > $STARTDIR/Scripts/.config/mister-cdrdao/${system}.dat
  rm ${system}.zip
done
