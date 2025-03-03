import os
import shutil
import sys
import struct
import hashlib
import xml.etree.ElementTree as ET
import struct

def reverse_byte_order_16bit(input_file, output_file, padding_bytes=0):
    with open(input_file, "rb") as f_in, open(output_file, "wb") as f_out:
        # Write zero-padding at the beginning
        f_out.write(b'\x00' * padding_bytes)
        
        while chunk := f_in.read(2):  # Read 16-bit (2 bytes) at a time
            if len(chunk) < 2:
                break  # Ignore incomplete data (in case of odd bytes in file)
            swapped = struct.pack("<H", struct.unpack(">H", chunk)[0])  # Swap endian
            f_out.write(swapped)

root = ET.parse("psx.dat").getroot()
origFile = sys.argv[1]
f = open(origFile, "r")
newFile = sys.argv[1];
o = open("temp_" + newFile, "w")
totalFile = f.read();
lines = totalFile.split("\n");

if len(sys.argv) > 2:
    audioFlag = False
else:
    audioFlag = True

renamed = False
binaryFile = ""
trackCount = 0;
for line in lines:
    parts = line.strip().split(" ");
    match parts[0].strip():
        case 'FILE':
            trackCount = trackCount + 1
            binaryFile=line.strip().split("\"")[1]
            md5sum = hashlib.md5(open(binaryFile, "rb").read()).hexdigest()
            if not renamed:
                # find the game by checksum if possible
                # if we don't find it, we leave the name as it was
                game = root.find(f'game/rom[@md5=\'{md5sum}\']/..')
                renamed = True
                if game is not None:
                    os.remove("temp_" + newFile)
                    newFile = game.attrib['name']
                    print(f'Found game in redump database: {newFile}')
                    o.close()
                    o = open(f'{newFile}.cue',"w")
                    if audioFlag:
                        newFileName = f'{newFile} (Track {trackCount}).bin'
                    else:
                        newFileName = f'{newFile}.bin'
                else:
                    o.close()
                    shutil.copy(origFile, f'{origFile}.bak')
                    os.remove("temp_" + newFile)
                    o = open(origFile, "w")
            else:
                if audioFlag:
                    newFileName = f'{newFile} (Track {trackCount}).bin'
                else:
                    newFileName = f'{newFile}.bin'

            o.write(f'FILE "{newFileName}" BINARY\n')
            trackNumber = ""
            trackType = ""
            trackIndexSeq = ""
        case 'TRACK':
            trackNumber = parts[1]
            trackType = parts[2]
            if trackType == 'AUDIO':
                print(f'Padding and reversing audio track {trackNumber} using file {binaryFile}')
                reverse_byte_order_16bit(binaryFile, newFileName, 0)
            else:
                os.rename(binaryFile, newFileName)
            o.write(f'  TRACK {trackNumber} {trackType}\n')
        case 'INDEX':
            trackIndexSeq = parts[1]
            indexTime = parts[2]
            if trackType == 'AUDIO' and trackIndexSeq == '01':
                indexTime = "00:02:00"
            o.write(f'    INDEX {trackIndexSeq} {indexTime}\n')

o.close()
f.close()
