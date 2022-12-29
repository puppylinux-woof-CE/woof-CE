#!/bin/sh

SOUND_CMD="-soundhw all"
FLASH_CMD=""

CONTINUE_WO_ERROR=0 # continue without spelling out error? Useful when the previous was such a flag which accepts its next cli option as well
ISO_PATH_PROVIDED=0
IMG_PATH_PROVIDED=0
for cli_flag in $@; do
	case $cli_flag in
		--help|-h)
			echo \
"Run your self built Puppy in qemu!

Usage: runqemu_woof.sh [OPTIONS] -iso [ISO FILE]

Option			Meaning
 -h, --help		 Show this help.
 --no-sound		 Disable sound in opened VM.
 -img			 Use this as '-img [Disk Image '.img' File]'.
 -flash			 Use this as '-flash /dev/[BLOCK DEVICE NAME]'.

Notes:
  1. QEMU is required to run this application.
  2. [ISO FILE] is the path to the generated '.iso' file. This is necessary
     field.
  3. Disk Image file with '.img' file format is a file which can be used as a
     'virtual storage drive (hard drive)'. Using this is optional, but can be
     used if you want to save some of your work in the qemu session. Please
     refer https://qemu-project.gitlab.io/qemu/system/images.html for tutorial
     on creating one.
  4. '-flash' can be used to allow QEMU to use external flash storage device.
     You can use 'lsblk' to determine the [BLOCK DEVICE NAME] assigned by the
     kernel to your flash device."
			exit
			;;
		-iso)
			shift

			[ ! $1 ] && echo "Please specify the path to a valid bootable ISO image." && exit 1
			[ ! -f $1 ] && echo "ISO image '$1' not found. Please specify the path to a valid bootable ISO image." && exit 1

			ISO_PATH=$1

			shift

			CONTINUE_WO_ERROR=1
			ISO_PATH_PROVIDED=1
			;;
	        -img)
			shift

			[ ! $1 ] && echo "Please specify the path to a 'IMG' disk image." && exit 1
			[ ! -f $1 ] && echo "Disk image '$1' not found. Please refer https://qemu-project.gitlab.io/qemu/system/images.html for tutorial on creating one." && exit 1

			IMG_PATH=$1

			shift

			CONTINUE_WO_ERROR=1
			IMG_PATH_PROVIDED=1
			;;
		-flash)
			shift

			[ ! $1 ] && echo "Please specify block device name for flash drive to be used." && exit 1
                        if ! test -b $1; then
				echo "'$1' is not a block device."
				exit 1
			fi

			FLASH_CMD="$FLASH_CMD -drive file=$1"

			shift

			CONTINUE_WO_ERROR=1
			;;
		--no-sound)
			SOUND_CMD=""
			shift
			;;
		*)
			if [ $CONTINUE_WO_ERROR -eq 1 ]; then
				CONTINUE_WO_ERROR=0
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

[ $ISO_PATH_PROVIDED -eq 0 ] && echo "Please specify the path to a valid bootable ISO image." && exit 1

EXTRA_CLI_FLAGS="-boot d -cdrom $ISO_PATH"

[ $IMG_PATH_PROVIDED -eq 1 ] && EXTRA_CLI_FLAGS="$EXTRA_CLI_FLAGS -hda $IMG_PATH"

[ "$REDIR" ] && REDIR="-redir tcp:$REDIR_PORT::22"
$QEMU -sdl -vga $VGA_TYPE -enable-kvm -m $MEM $REDIR $EXTRA_CLI_FLAGS $SOUND_CMD $FLASH_CMD
