# mister-cdrdao

This project helps you rip discs for the MiSTer FPGA system. Specifically, it simplifies the process of building cdrdao for Linux on the MiSTer FPGA. Currently, it consists of just two scripts and does not include cdrdao or any MiSTer files. Instead, it retrieves the necessary resources to build a cdrdao binary and packages it into a .tar.gz file, ready for transfer to your MiSTer.

## Requirements

Currently, this is setup to build on Ubuntu in WSL. Other platforms will be investigated as needed.

## build-mister-cdrdao.sh

This script ensures that WSL is up-to-date and installs the necessary Ubuntu packages. It then retrieves and installs the ARM development tools (compiler, linker, etc.). After setting up the environment, the script downloads the cdrdao source code and compiles it using the appropriate ARM tools, producing executables compatible with Linux for MiSTer.

Currently, the script uses cdrdao version 1.2.5, as some older versions—particularly 1.2.3, which is labeled as "latest"—have compilation issues.

Error checking is minimal at the moment, but enhancements are planned to better capture failures and reduce the need for user troubleshooting.

The final output of this script is `mister-cdrdao.tar.gz`.

## ripdisc.sh

This script uses cdrdao to rip the disc to the current directory, naming the CUE/BIN files after the disc label. If no label is found, the files will default to `unknown`.

Future updates will integrate data from redump.org to compare the BIN's checksum, allowing the script to identify the platform and assign a more accurate name to the output. Stay tuned!