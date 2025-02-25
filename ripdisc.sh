DISCNAME=`lsblk -n -o LABEL /dev/sr0 | sed 's/(.*)/$1/'`
if [ -z "$DISCNAME" ]; then
	DISCNAME=unknown
fi
echo Ripping $DISCNAME
./cdrdao read-cd --read-raw --datafile $DISCNAME.bin --device /dev/sr0 --driver generic-mmc-raw $DISCNAME.toc
./toc2cue $DISCNAME.toc $DISCNAME.cue
rm $DISCNAME.toc
