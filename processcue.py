import os
import shutil
import sys
import struct
import xml.etree.ElementTree as ET
import hashlib
from pathlib import Path

def reverse_byte_order_16bit(input_file, output_file, padding_bytes=0):
    # Reverse the byte order of 16-bit samples in a binary file.
    with open(input_file, "rb") as f_in, open(output_file, "wb") as f_out:
        f_out.write(b'\x00' * padding_bytes)  # Write padding
        
        while chunk := f_in.read(2):  # Read in 2-byte chunks
            if len(chunk) == 2:
                swapped = struct.pack("<H", struct.unpack(">H", chunk)[0])  # Swap endian
                f_out.write(swapped)

def calculate_md5(file_path):
    md5 = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):  # Read in chunks
            md5.update(chunk)
    return md5.hexdigest()

def parse_cue_file(orig_file, psx_db, saturn_db, audio_flag):
    platform = "PSX"
    """Parse and update the .cue file based on Redump database matching."""
    orig_file = Path(orig_file)
    # if we can't get the name of the game we'll swap back to this temp_ version of
    # the file and update it
    temp_file = Path(f"temp_{orig_file.name}")
    track_count = 0
    renamed = False
    binary_file = ""

    with orig_file.open("r") as f, temp_file.open("w") as out_file:
        lines = f.read().split("\n")

        for line in lines:
            parts = line.strip().split(" ")
            if not parts:
                continue
            
            command = parts[0]
            
            if command == "FILE":
                track_count += 1
                binary_file = line.split("\"")[1]
                
                # Compute MD5 checksum for file matching
                md5sum = calculate_md5(binary_file)

                if not renamed:
                    game = psx_db.find(f'game/rom[@md5="{md5sum}"]/..')
                    if game is None:
                        platform = "Saturn"
                        game = saturn_db.find(f'game/rom[@md5="{md5sum}"]/..')
                    renamed = True
                    if game is not None:
                        new_file_name = game.attrib["name"]
                        print(f"Found game in Redump database: {new_file_name}")
                        out_file.close()
                        out_file = open(f"{new_file_name}.cue", "w")
                    else:
                        platform = ""
                        # backup original, just in case
                        shutil.copy(orig_file, f"{orig_file}.bak")
                        new_file_name = orig_file.stem
                
                new_track_name = f"{new_file_name} (Track {track_count}).bin" if audio_flag else f"{new_file_name}.bin"
                out_file.write(f'FILE "{new_track_name}" BINARY\n')

            elif command == "TRACK":
                track_number = parts[1]
                track_type = parts[2]

                if track_type == "AUDIO":
                    print(f"Padding and reversing audio track {track_number} from {binary_file}")
                    reverse_byte_order_16bit(binary_file, new_track_name)
                else:
                    os.rename(binary_file, new_track_name)

                out_file.write(f"  TRACK {track_number} {track_type}\n")

            elif command == "INDEX":
                track_index = parts[1]
                index_time = parts[2]

                if track_type == "AUDIO" and track_index == "01":
                    index_time = "00:02:00"  # Adjust lead-in for audio tracks

                out_file.write(f"    INDEX {track_index} {index_time}\n")

    os.remove(temp_file)  # Clean up temporary file
    return platform

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: script.py <cue_file> [no_audio_flag]")
        sys.exit(1)

    cue_file = sys.argv[1]
    audio_flag = len(sys.argv) == 2  # Default to True if no second argument

    psx_db = ET.parse("psx.dat").getroot()
    saturn_db = ET.parse("saturn.dat").getroot()
    print(f"Platform={parse_cue_file(cue_file, psx_db, saturn_db, audio_flag)}\n")

