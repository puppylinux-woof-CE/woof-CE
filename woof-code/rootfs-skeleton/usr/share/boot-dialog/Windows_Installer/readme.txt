# LICK
LICK is a free program to install Linux from Windows without burning a CD or
using a USB. It is as simple as installing and running LICK, selecting a Linux
ISO image, and clicking install. A few seconds later, you can reboot into
Linux. Currently only Puppy Linux-based distributions are supported.

LICK runs on any Windows version, from Windows XP to Windows 10. Check below
for any special notes on your Windows version type.

# Download
You can download the latest version of LICK from
	https://github.com/noryb009/lick/releases/latest

# Windows Version Notes
## Windows 8, 8.1 and 10
Windows 8 and up have a feature called 'Fast Startup'. This **cannot** be
enabled if LICK is installed. LICK disables Fast Startup upon installation.

## UEFI Systems with Secure Boot
LICK supports secure boot, but requires a manual step during the first
reboot.

1. On the first reboot, if you see a blue screen with writing, press enter
   to select `OK`.
2. Press enter again to select `Enroll Hash`.
3. Use the up and down arrow keys to highlight `loader.efi`, and press enter.
4. Press the down arrow to select `Yes`, then press enter.
5. Use the down arrow to highlight `Exit`, then press enter.

On subsequent reboots, these steps will not need to be taken.
