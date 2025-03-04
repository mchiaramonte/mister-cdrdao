import os
import shutil
import sys
import struct
import xml.etree.ElementTree as ET
import hashlib
from pathlib import Path
import mmap

def reverse_byte_order_16bit(input_file, output_file, padding_bytes=0, chunk_size=4096):
    print(output_file, end='')
    """Efficiently reverse 16-bit byte order in large chunks for slow drives."""
    with open(input_file, "rb") as f_in, open(output_file, "wb") as f_out:
        # Write initial padding
        f_out.write(b'\x00' * padding_bytes)

        # Memory-map the input file (fast reading)
        with mmap.mmap(f_in.fileno(), 0, access=mmap.ACCESS_READ) as mm:
            buffer = bytearray(chunk_size)

            for i in range(0, len(mm), chunk_size):
                print(".", end='', flush=True)
                chunk = mm[i : i + chunk_size]
                chunk_len = len(chunk)

                if chunk_len % 2 != 0:  # If odd number of bytes, ignore the last one
                    chunk = chunk[:-1]

                # Unpack as 16-bit big-endian and repack as little-endian in bulk
                swapped_chunk = struct.pack("<" + "H" * (chunk_len // 2), *struct.unpack(">" + "H" * (chunk_len // 2), chunk))

                # Extend buffer and write it all at once
                buffer[: len(swapped_chunk)] = swapped_chunk
                f_out.write(buffer[: len(swapped_chunk)])
    print("")

def calculate_md5(file_path):
    md5 = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):  # Read in chunks
            md5.update(chunk)
    return md5.hexdigest()

def parse_cue_file(source_cue_file, psx_db, saturn_db, audio_flag):
    platform = "PSX"
    """Parse and update the .cue file based on Redump database matching."""
    source_cue_file = Path(source_cue_file)
    destination_cue_file = Path(source_cue_file)
    # if we can't get the name of the game we'll swap back to this temp_ version of
    # the file and update it
    track_count = 0
    binary_file = ""

    with source_cue_file.open("r") as input_file:
        lines = input_file.read().split("\n")

        # Search for the game in the dat files using the checksum.
        for line in lines:
            parts = line.strip().split(" ")
            command = parts[0]
            
            if command == "FILE":
                source_cue_file = line.split("\"")[1]
                md5sum = calculate_md5(source_cue_file)
                psgame = psx_db.find(f'game/rom[@md5="{md5sum}"]/..')
                satgame = saturn_db.find(f'game/rom[@md5="{md5sum}"]/..')
                finalgame = psgame or satgame
                if finalgame is not None:
                    if satgame is not None:
                        platform = "Saturn"
                    else:
                        platform = "PSX"
                    
                    game_name = finalgame.attrib["name"]
                    print(f"\n *** Found game in Redump database: {game_name} ***")
                    destination_cue_file = Path(f"{game_name}.cue")
                else:
                    # we're going with the original file, so make a backup copy before overwriting it
                    shutil.copy(source_cue_file, f"{source_cue_file}.bak")
                break

        with destination_cue_file.open("w") as output_file:
            for line in lines:
                parts = line.strip().split(" ")
                if not parts:
                    continue
                
                command = parts[0]
                
                if command == "FILE":
                    track_count += 1
                    binary_file = line.split("\"")[1]

                    new_track_name = f"{game_name} (Track {track_count}).bin" if audio_flag else f"{game_name}.bin"
                    output_file.write(f'FILE "{new_track_name}" BINARY\n')
                    shutil.copy(binary_file, new_track_name)

                elif command == "TRACK":
                    track_number = parts[1]
                    track_type = parts[2]

                    if track_type == "AUDIO":
                        print(f"Padding and reversing audio track {track_number} from {binary_file}")
                        reverse_byte_order_16bit(binary_file, new_track_name, 352800)
                        os.remove(binary_file)
                    else:
                        os.rename(binary_file, new_track_name)

                    output_file.write(f"  TRACK {track_number} {track_type}\n")

                elif command == "INDEX":
                    track_index = parts[1]
                    index_time = parts[2]

                    if track_type == "AUDIO" and track_index == "01":
                        index_time = "00:02:00"  # Adjust lead-in for audio tracks

                    output_file.write(f"    INDEX {track_index} {index_time}\n")

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

