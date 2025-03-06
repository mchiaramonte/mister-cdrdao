#!/bin/sh
wget http://redump.org/datfile/psx/ -O psx.zip
wget http://redump.org/datfile/ss/ -O saturn.zip
wget http://redump.org/datfile/mcd/ -O megacd.zip
wget http://redump.org/datfile/pce/ -O tgcd.zip
wget http://redump.org/datfile/ngcd/ -O ngcd.zip
unzip -p psx.zip > PSX.dat
unzip -p saturn.zip > Saturn.dat
unzip -p megacd.zip > MegaCD.dat
unzip -p tgcd.zip > TGFX16-CD.dat
unzip -p ngcd.zip > NeoGeo-CD.dat
rm psx.zip
rm saturn.zip
rm megacd.zip
rm tgcd.zip
rm ngcd.zip
