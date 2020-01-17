#!/bin/sh
# James Budiono 2011, 2013, 2015
# puppy test/compilation sandbox
# this version uses rw image
# version 2 - will ask for SFS, and now we use dialog for rw image file location/creation
# version 3 - change awk/sed script combo to one sed script
# version 4 - replace sed script with awk, make sure it will handle oddball cases (loop-N and pup_ro-N don't match)
# version 5 - add compatibility when running with pup_rw=tmpfs (step 2.a)
# version 6 - (2012) adapted to be more flexible - for Fatdog64 600
# version 7 - (2012) cleanup mounts if if we are killed
# version 8 - (2013) re-launch in terminal if we aren't in terminal
# version 9 - (2013) enable running multiple sandboxes
# version 10 - (2015) use pid/mount namespaces if available

# 0. directory locations
#. $BOOTSTATE_PATH # AUFS_ROOT_ID
#XTERM="defaultterm"
XTERM=urxvt
SANDBOX_ROOT=/mnt/sb
FAKEROOT=$SANDBOX_ROOT/fakeroot   # mounted chroot location of sandbox - ie, the fake root
SANDBOX_IMG=$SANDBOX_ROOT/sandbox # mounted rw image of the sandbox disk image
SANDBOX_ID=
TMPFILE=$(mktemp -p /tmp)
# use namespaces if available
#[ -e /proc/1/ns/pid ] && [ -e /proc/1/ns/mnt ] && type unshare >/dev/null && USE_NS=1

# umount all if we are accidentally killed
trap 'umountall' 1
umountall() {
	{
	umount -l $FAKEROOT/$SANDBOX_IMG
	umount -l $FAKEROOT/tmp
	umount -l $FAKEROOT/proc
	umount -l $FAKEROOT/sys
	umount -l $FAKEROOT/dev
	
	umount -l $FAKEROOT
	umount -l $SANDBOX_IMG
	rmdir $FAKEROOT
	rmdir $SANDBOX_IMG
	} 2> /dev/null
}

# 0.1 must be root
if [ $(id -u) -ne 0 ]; then
	echo "You must be root to use sandbox."
	exit
fi

# 0.2 cannot launch sandbox within sandbox
if [ "$AUFS_ROOT_ID" != "" ] ; then
	grep -q $SANDBOX_ROOT /sys/fs/aufs/$AUFS_ROOT_ID/br0 &&
		echo "Cannot launch sandbox within sandbox." && exit
fi

# 0.3 help
case "$1" in
	--help|-h)
	echo "Usage: ${0##*/} [/path/to/persistent.disk-image]"
	echo "Starts a persistent sandbox. Type 'exit' to leave."
	echo "Path is optional, you will be asked to select or create one if not specified."
	exit
esac

# 0.4 if not running from terminal but in Xorg, then launch via terminal
! [ -t 0 ] && [ -n "$DISPLAY" ] && exec $XTERM -e "$0" "$@"
! [ -t 0 ] && exit

# 0.5 is this the first sandbox? If not, then create another name for mountpoints
if grep -q $FAKEROOT /proc/mounts; then
	FAKEROOT=$(mktemp -d -p $SANDBOX_ROOT ${FAKEROOT##*/}.XXXXXXX)
	SANDBOX_ID=".${FAKEROOT##*.}"
	SANDBOX_IMG=$SANDBOX_ROOT/${SANDBOX_IMG##*/}${SANDBOX_ID}
	rmdir $FAKEROOT
fi

# 1. get aufs system-id for the root filesystem
if [ -z "$AUFS_ROOT_ID" ] ; then
	AUFS_ROOT_ID=$(
		awk '{ if ($2 == "/" && $3 == "aufs") { match($4,/si=[0-9a-f]*/); print "si_" substr($4,RSTART+3,RLENGTH-3) } }' /proc/mounts
	)
fi

# 2. get branches, then map branches to mount types or loop devices 
items=$(
{ echo ==mount==; cat /proc/mounts; 
  echo ==losetup==; losetup-FULL -a; 
  echo ==branches==; ls -v /sys/fs/aufs/$AUFS_ROOT_ID/br[0-9]* | xargs sed 's/=.*//'; } | \
  awk '
  /==mount==/ { mode=1 }
  /==losetup==/ { mode=2 }
  /==branches==/ { mode=3 }
  {
	if (mode == 1) {
		# get list of mount points, types, and devices - index is $3 (mount points)
		mountdev[$2]=$1
		mounttypes[$2]=$3
	} else if (mode == 2) {
		# get list of loop devices and files - index is $1 (loop devs)
		sub(/:/,"",$1)
		sub(/.*\//,"",$3); sub(/)/,"",$3)
		loopdev[$1]=$3
	} else if (mode == 3) {
		# map mount types to loop files if mount devices is a loop
		for (m in mountdev) {
			if ( loopdev[mountdev[m]] != "" ) mounttypes[m]=loopdev[mountdev[m]]
		}
		# for (m in mountdev) print m " on " mountdev[m] " type " mounttypes[m]
		mode=4
	} else if (mode==4) {
		# print the branches and its mappings
		if ($0 in mounttypes){
		  print $0, mounttypes[$0], "on"
		}
		else {
			MNT_PATH=$0
			sub(/^.*[\/]/,"")
			print MNT_PATH, $0, "on"
		}
	} 
  }
' 
)
# '

# 3. Ask user to choose the SFS
dialog --separate-output --backtitle "rw image sandbox" --title "sandbox config" \
	--checklist "Choose which SFS you want to use" 0 0 0 $items 2> $TMPFILE
chosen="$(cat $TMPFILE)"

clear
if [ -z "$chosen" ]; then
	echo "Cancelled or no SFS is chosen - exiting."
	exit 1
fi

# 4. convert chosen SFS to robranches
robranches=""
for a in $(cat $TMPFILE) ; do
	robranches=$robranches:$a=ro
done
rm $TMPFILE

# 5. get location of rw image
if [ -z "$1" ]; then
	# location not specified - then ask
	dialog --backtitle "rw image sandbox" --title "choose rw image" \
	--extra-button --extra-label "Create" --ok-label "Locate" \
	--yesno "You didn't specify the location of the rw image file. Do you want to locate existing file, or do you want to create a new one?" 0 0
	case $? in
		0) # ok - locate
			dialog --backtitle "rw image sandbox" --title "Specify location of existing rw image" --fselect `pwd` 8 60 2> $TMPFILE
			rwbranch=`cat $TMPFILE`
			rm $TMPFILE
			if [ -n "$rwbranch" ]; then
				if [ ! -f "$rwbranch" ]; then
					echo "$rwbranch doesn't exist - exiting."
					exit					
				fi
			else
				echo "You didn't specify any file or you pressed cancel. Exiting."
				exit
			fi
			;;
		3) # create
			echo "create"
			dialog --backtitle "rw image sandbox" --title "Specify name and path of new the file" --fselect `pwd` 8 60 2> $TMPFILE
			rwbranch=`cat $TMPFILE`
			rm $TMPFILE
			if [ -n "$rwbranch" ]; then
				if [ -f "$rwbranch" ]; then
					echo "$rwbranch already exist - exiting."
					exit
				else
					# get the size
					dialog --title "Create new rw image" --inputbox "Specify size (in megabytes)" 0 40 100 2> $TMPFILE
					size=`cat $TMPFILE`
					rm $TMPFILE
					
					if [ -n "$size" ]; then
						if dd if=/dev/zero of="$rwbranch" bs=1 count=0 seek="$size"M; then
							if ! mke2fs -F "$rwbranch"; then
								echo "I fail to make an ext2 filesystem at $rwbranch, exiting."
								exit
							fi
						else
							echo "I fail to create a ${size}M file at $rwbranch, exiting."
							exit
						fi
					else
						echo "You didn't specify the size or your press cancel. Exiting."
						exit
					fi					
				fi
			else
				echo "You didn't specify any file or you pressed cancel. Exiting."
				exit
			fi
			;;
		1 | 255) # 1 is cancel, 255 is Escape
			;&
		*) # invalid input - treat as cancel
			echo "Cancelled - exiting."
			exit
			;;
	esac
else
	# use what we've been given
	rwbranch="$1"
fi

# 4. make the mountpoints if not exist  yet
mkdir -p $FAKEROOT $SANDBOX_IMG

# 5. do the magic - mount the rw image first, and then the rest with aufs
if mount -o loop "$rwbranch" $SANDBOX_IMG; then
	if mount -t aufs -o "br:$SANDBOX_IMG=rw$robranches" aufs $FAKEROOT; then
		# 5. record our new aufs-root-id so tools don't hack real filesystem
		SANDBOX_AUFS_ID=$(grep $FAKEROOT /proc/mounts | sed 's/.*si=/si_/; s/ .*//') #'
		sed -i -e '/AUFS_ROOT_ID/ d' $FAKEROOT/etc/BOOTSTATE 2> /dev/null
		echo AUFS_ROOT_ID=$SANDBOX_AUFS_ID >> $FAKEROOT/etc/BOOTSTATE
		
		# 5. sandbox is ready, now just need to mount other supports - pts, proc, sysfs, usb and tmp
		mkdir -p $FAKEROOT/dev $FAKEROOT/sys $FAKEROOT/proc $FAKEROOT/tmp
		mount -o rbind /dev $FAKEROOT/dev
		mount -t sysfs none $FAKEROOT/sys
		mount -t proc none $FAKEROOT/proc
		mount -o bind /tmp $FAKEROOT/tmp
		mkdir -p $FAKEROOT/$SANDBOX_IMG
		mount -o bind $SANDBOX_IMG $FAKEROOT/$SANDBOX_IMG	# so we can access it within sandbox
		
		# 6. optional copy, to enable running sandbox-ed xwin 
		cp /usr/share/sandbox/* $FAKEROOT/usr/bin 2> /dev/null
		
		# 7. make sure we identify ourself as in sandbox - and we're good to go!
		echo -e '\nexport PS1="sandbox'${SANDBOX_ID}'# "' >> $FAKEROOT/etc/shinit #fatdog 600
		sed -i -e '/^PS1/ s/^.*$/PS1="sandbox'${SANDBOX_ID}'# "/' $FAKEROOT/etc/profile # earlier fatdog
		echo "Starting sandbox now."
		if [ $USE_NS ]; then
			unshare -f -p --mount-proc=$FAKEROOT/proc chroot $FAKEROOT
		else
			chroot $FAKEROOT
		fi

		# 8. done - clean up everything 
		umountall
		echo "Leaving sandbox."
	else
		echo "Unable to mount aufs br:$SANDBOX_IMG=rw$robranches"
		umount -l $SANDBOX_IMG	
	fi
else
	echo "unable to mount rw image: $rwbranch"
fi
