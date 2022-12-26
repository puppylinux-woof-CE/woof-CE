#!/bin/sh

PREV_ISO_or_IMG=0
IMG_PATH_PROVIDED=0
for cli_flag in $@; do
	case $cli_flag in
		--help|-h)
			echo \
"Run your self built Puppy in qemu!

Usage: runqemu_woof.sh [OPTIONS] -iso [ISO FILE]

Option			Meaning
 -h, --help		 Show this help.
 -img			 Use this as '-img [Disk Image '.img' File]'.

Notes:
  1. QEMU is required to run this application.
  2. [ISO FILE] is the path to the generated '.iso' file. This is necessary
     field.
  3. Disk Image file with '.img' file format is a file which can be used as a
     'virtual storage drive (hard drive)'. Using this is optional, but can be
     used if you want to save some of your work in the qemu session. Please
     refer https://qemu-project.gitlab.io/qemu/system/images.html for tutorial
     on creating one."
			exit
			;;
		-iso)
			shift

			[ ! $1 ] && echo "Please specify the path to a valid bootable ISO image." && exit 1
			[ ! -f $1 ] && echo "ISO image '$1' not found. Please specify the path to a valid bootable ISO image." && exit 1

			ISO_PATH=$1

			shift

			PREV_ISO_or_IMG=1 # previous was -iso or -img
			;;
	        -img)
			shift

			[ ! $1 ] && echo "Please specify the path to a 'IMG' disk image." && exit 1
			[ ! -f $1 ] && echo "Disk image '$1' not found. Please refer https://qemu-project.gitlab.io/qemu/system/images.html for tutorial on creating one." && exit 1

			IMG_PATH=$1

			shift

			PREV_ISO_or_IMG=1
			IMG_PATH_PROVIDED=1
			;;
		*)
			if [ $PREV_ISO_or_IMG -eq 1 ]; then
				PREV_ISO_or_IMG=0
				continue
			fi

			echo "Unknown option $cli_flag. Please run 'runqemu_woof.sh --help' for help."
			exit 1
			;;
	esac
done

VGA_TYPE=${VGA_TYPE:-std}
REDIR_PORT=${REDIR_PORT:-3222}
MEM=${MEM:-1024}

QEMU=qemu-system-x86_64
! type $QEMU >/dev/null 2>/dev/null && QEMU=qemu-system-x86
! type $QEMU >/dev/null 2>/dev/null && QEMU=qemu-system-i386
! type $QEMU >/dev/null 2>/dev/null && echo "Sorry I can't find QEMU. Please install one." && exit 1

[ ! $ISO_PATH ] && echo "Please specify the path to a valid bootable ISO image." && exit 1

EXTRA_CLI_FLAGS="-cdrom $ISO_PATH"

[ $IMG_PATH_PROVIDED -eq 1 ] && EXTRA_CLI_FLAGS="-boot d -cdrom $ISO_PATH -hda $IMG_PATH"

[ "$REDIR" ] && REDIR="-redir tcp:$REDIR_PORT::22"
$QEMU -sdl -vga $VGA_TYPE -enable-kvm -m $MEM $REDIR $EXTRA_CLI_FLAGS
