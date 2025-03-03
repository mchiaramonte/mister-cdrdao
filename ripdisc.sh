echo "Waiting for drive..."
# Do this to wait for the drive to be ready
blkid 
# Try to get a disc label
DISCNAME=`lsblk -n -o LABEL /dev/sr0 | sed 's/(.*)/$1/'`
if [ -z "$DISCNAME" ]; then
	DISCNAME=unknown
fi
echo Ripping $DISCNAME
# Dump the disc and convert the toc to cue
./cdrdao read-cd --read-raw --datafile $DISCNAME.bin --device /dev/sr0 --driver generic-mmc-raw $DISCNAME.toc
./toc2cue $DISCNAME.toc $DISCNAME.cue

# if the CUE contains AUDIO tracks
if [ `grep -e AUDIO $DISCNAME.cue | wc -l` -gt 0 ]; then
	# Split the BIN file
	echo "Audio tracks detected. Splitting BIN/CUE..."
	./binmerge -s $DISCNAME.cue $DISCNAME -o ./output
	rm $DISCNAME.bin $DISCNAME.cue 
	mv ./output/* .
	AUDIOFLAG=
else
	AUDIOFLAG=--no-audio
fi

PLATFORM=`python3 ./processcue.py $DISCNAME.cue $AUDIOFLAG | tee /dev/stderr | grep -i Platform | awk -F= '{print $2}'` 

# Default to PSX if the platform was not determined
if [ -z "$PLATFORM" ]; then
	PLATFORM=PSX
fi

echo "Moving to $PLATFORM directory..."
mv *.cue /media/fat/games/$PLATFORM/
mv *.bin /media/fat/games/$PLATFORM/

echo "Complete!"
rm $DISCNAME.toc
