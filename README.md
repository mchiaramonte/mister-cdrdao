# Game dumping with cdrdao for MiSTer FPGA

This project helps you rip discs for the MiSTer FPGA system. Specifically, it simplifies the process of building cdrdao for Linux on the MiSTer FPGA. It does not include the source code for cdrdao or any of the redump data. Instead, it retrieves the necessary resources to build a cdrdao binary and packages it with its helper scripts and redump data files it into a .tar.gz file, ready for transfer to your MiSTer. This should work for most discs, including discs which have audio tracks. It will not produce dumps that are exact to redump standards, but it the data file (track 1) md5 should match what's in the redump database so that the files can be renamed properly and platform can be detected. This discrepency is likely due to the way I'm padding the audio tracks compared to how MPF and related tools does this for redump. The content of the audio files appears to match, in all cases, against the verified dumps that I produce with my Plextor drive, but the padding is apparently off enough that you end up with something that's not 100% md5 equivalent. This may be fixed in the future.

## Setup

Add the following to `/media/fat/downloader.ini` on your MiSTer:

```ini
[mchiaramonte/mister-cdrdao]
db_url = https://raw.githubusercontent.com/mchiaramonte/mister-cdrdao/db/db.json.zip
```

Then run `update` or `update_all` from the `Scripts` menu on your MiSTer.

## ripdisc.sh

This script uses cdrdao to rip the disc to the current directory, naming the CUE/BIN files after the disc label. If no label is found, the files will default to `unknown`. binmerge is used to split the BIN file and create an updated CUE file if the file has multiple tracks (i.e. mixed mode data and audio). processcue.py processes audio tracks to fix them because they're not padded and have their byte order backwards. If the track 1 md5 matches the checksum in the redump file for either Playstation 1 or Saturn, the whole BIN/CUE collection is renamed to that game accordingly.

