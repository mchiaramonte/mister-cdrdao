#!/bin/sh
wget http://redump.org/datfile/psx/ -O psx.zip
wget http://redump.org/datfile/ss/ -O saturn.zip
unzip -p psx.zip > psx.dat
unzip -p saturn.zip > saturn.dat
rm psx.zip
rm saturn.zip
