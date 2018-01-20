#!/bin/bash
# James Budiono 2011, 2013, 2014
# sb2dir.sh (sandbox to directory) - replacement for pet4sand.sh
# copy contents of sandbox to dir, removing all known sandboxing files
# update 2013 - enable choosing from multiple sandboxes
SANDBOX_ROOT=/mnt/sb
SANDBOX=$SANDBOX_ROOT/sandbox
TARGET_ROOT=/tmp

case "$1" in
	""|--help|-h)
	echo "Usage: ${0##*/} dirname [/path/to/sandbox]"
	echo "Extracts content of sandbox into $TARGET_ROOT/\$dirname directory"
	exit
esac

DIRNAME="$1"
[ "$2" ] && SANDBOX="$2"

cd "$SANDBOX"
find . | sed -ne "
#filters - what we want to remove from output (all the whiteout files, and our own test profile/apps)
/\.wh\./ d
/\/etc\/profile/ d
/\/etc\/shinit/ d
/\/etc\/hosts/ d
/\/etc\/hostname/ d
/\/etc\/inittab/ d
/\/etc\/\.XLOADED/ d
/\/etc\/BOOTSTATE/ d
/\/etc\/rc\.d\/rc\.sysinit\.lxc/ d
/\/sbin\/init/ d
/\/usr\/bin\/xwin/ d
/\/usr\/bin\/wmexit/ d
/\/var\/run\/utmp/ d
/\/var\/log\/wtmp/ d
/\/dev\/null/ d
/\/root\/\.Xauthority/ d
p" | cpio -d -p "$TARGET_ROOT/$DIRNAME"
cd "$TARGET_ROOT"
find "$DIRNAME" -type d -empty -delete # delete all empty directories
echo Output in $TARGET_ROOT/$DIRNAME
