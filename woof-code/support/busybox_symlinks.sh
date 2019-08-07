#!/bin/sh
#
# param: <rootdir>
#
# does not overwrite existing files
#

RFS="$1"

if [ ! -d "$RFS" ] ; then
	echo "Need a directory. Busybox must be in <directory>/bin/busybox"
	exit 1
fi
if [ ! -f "$RFS/bin/busybox" ] ; then
	echo "$RFS/bin/busybox does not exist!"
	exit 1
fi

#==============================================================

cd $RFS

rm -f /tmp/busybox.lst

lst=$(./bin/busybox --list-full)
if [ "$lst" ] ; then
	echo "$lst" > /tmp/busybox.lst
elif [ -f ./bin/busybox.lst ] ; then
	cp -f ./bin/busybox.lst /tmp/busybox.lst
else
	echo "ERROR: could not get applet list"
	exit 1
fi

#==============================================================

echo
echo "Creating busybox symlinks..."
echo

while read ONEAPPLET
do

	ONEPATH="${ONEAPPLET%/*}"  #dirname $ONEAPPLET
	N="${ONEAPPLET##*/}"       #basename $ONEAPPLET

	#- exceptions
	case $N in
		# Archival utilities
		ar)       continue ;; # devx

		# Coreutils
		install)  continue ;; # devx

		# Console Utilities
		# Debian Utilities
		# klibc-utils

		# Editors
		vi|ed)    continue ;;
		patch)    continue ;; # too primitive

		# Finding Utilities
		grep)     continue ;;
		egrep)    continue ;;
		fgrep)    continue ;;

		# Init Utilities
		# Login/Password Management Utilities

		# Linux Ext2 FS Progs
		chattr)  continue ;;
		fsck)    continue ;;
		lsattr)  continue ;;
		tune2fs) continue ;;

		# Linux Module Utilities

		# Linux System Utilities
		mkdosfs)   continue ;;
		mkfs.vfat) continue ;;
		mke2fs)    continue ;;
		mkfs.ext2) continue ;;
		taskset)   continue ;; # breaks winetricks

		# Miscellaneous Utilities
		strings)  continue ;; # devx

		# Networking Utilities
		# Print Utilities
		# Mail Utilities

		# Process Utilities
		killall5) continue ;; # kills everything

		# Runit Utilities
		# Shells
		# System Logging Utilities
	esac
	#-

	if [ -f bin/$N -o -f sbin/$N -o -f usr/bin/$N -o -f usr/sbin/$N ] ;then
		continue
	fi

	ln -sv /bin/busybox ${ONEPATH}/${N}

done < /tmp/busybox.lst

echo

### END ###