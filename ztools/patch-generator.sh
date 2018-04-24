#!/bin/bash
# A script to generate woof-CE patches against a running puppy (run without
# any arguments)  or the puppy.sfs (run with the 'sfs' argument).

Version=0.7

. /etc/DISTRO_SPECS
. /etc/rc.d/PUPSTATE

# Check if we are good to run
if [ "$(which git)" = "" ]; then
 Xdialog --title "Error" --msgbox \
 "Please install the devx sfs or just git from the repo." 0 0
 exit 1
fi
WDIR=$(pwd) # Should be just above your freshly cloned woof-CE git
if [ ! -d $WDIR/woof-CE ]; then
 # Check if script was started by "dropping" a file on it with ROX
 SCRIPT_PATH="`realpath $0`"
 if [ "${SCRIPT_PATH%/woof-CE/ztools/patch-generator.sh}" != "$SCRIPT_PATH" -a "$1" != '' ]; then
  WDIR="${SCRIPT_PATH%/woof-CE/ztools/patch-generator.sh}"
  cd $WDIR
 else
  Xdialog --title "Error" --msgbox \
  "This script should be in the same folder as the woof-CE git folder" 0 0
  exit 1
 fi
fi
GIT_BRANCH=$(cut -f3 -d'/' $WDIR/woof-CE/.git/HEAD)
if [ ! "$GIT_BRANCH" ]; then
 Xdialog --title "Error" --msgbox \
 "The woof-CE folder is not a git repo. Please clone the woof-CE git" 0 0
 exit 1
fi
if [ "$GIT_BRANCH" != "testing" -a "$GIT_BRANCH" != "rationalise" ]; then
 Xdialog --title "Error" --msgbox \
 "Your woof-CE repo is not in the testing or rationalise branch. Please run 'git checkout testing' or 'git checkout rationalise'" 0 0
 exit 1
fi
if [ "$GIT_BRANCH" = "testing" ]; then
 GIT_HEAD=$(cut -c 1-6 $WDIR/woof-CE/.git/refs/heads/testing)
 REMOTE_HEAD=$(git ls-remote https://github.com/puppylinux-woof-CE/woof-CE.git |
 grep 'refs/heads/testing' | cut -c 1-6)
elif [ "$GIT_BRANCH" = "rationalise" ]; then
 GIT_HEAD=$(cut -c 1-6 $WDIR/woof-CE/.git/refs/heads/rationalise)
 REMOTE_HEAD=$(git ls-remote https://github.com/puppylinux-woof-CE/woof-CE.git |
 grep 'refs/heads/rationalise' | cut -c 1-6)
fi
if [ "$REMOTE_HEAD" != "$GIT_HEAD" ]; then
 Xdialog --title "Error" --msgbox \
 "Your local repo is not in sysnc with the remote. Please run 'git pull --all'" 0 0
 exit 1
fi

if [ "$1" = "sfs" -a "$PUPMODE" = "2" ]; then
 Xdialog --title "Error" --msgbox \
 "There is no pup.sfs in full installs. Please run without the 'sfs' argument" 0 0
 exit 1
fi
# Make the patches
[ "$BUILD_FROM_WOOF" ] && FROMWOOF=_$(echo $BUILD_FROM_WOOF | cut -f 2 -d ';' | cut -c 1-6)
case "$1" in
 sfs) COMP_DIR=/initrd/pup_ro2
      PATCHES=woof_"$GIT_BRANCH""$GIT_HEAD"_patches_to_"$DISTRO_FILE_PREFIX"-"$DISTRO_VERSION"_sfs"$FROMWOOF"
 ;;
 '') COMP_DIR=
    PATCHES=woof_"$GIT_BRANCH""$GIT_HEAD"_patches_to_"$DISTRO_FILE_PREFIX"-"$DISTRO_VERSION""$FROMWOOF"
 ;;
 *) if [ ! -f "$1" ]; then
     echo "No such file: $1"
     Xdialog --title "Error" --msgbox "No such file: $1" 0 0
     exit 1
    elif [ "`expr "$1" : '.*\(woof-out\)'`" = '' ]; then
     echo "File must exist in woof-out_*"
     Xdialog --title "Error" --msgbox "File must exist in woof-out_*" 0 0
     exit 1
    fi
    mkdir -p $WDIR/patches
    cd $WDIR/woof-CE/woof-code
    WOOFOUT_DIR="`expr "$1" : '.*\(woof-out[^/]*\)'`"
    FILE="`expr "$1" : '.*woof-out[^/]*/\(.*\)'`"
    echo "Making patch from $FILE"
    diff -u -N $FILE ../../$WOOFOUT_DIR/$FILE > $WDIR/patches/$(basename $FILE).patch
    cd $WDIR
    Xdialog --title "Finished" --msgbox "Made patch from $FILE \n \
It can be found in \n \
$WDIR/patches/" 0 0
    exit
 ;;
esac
mkdir -p $WDIR/$PATCHES
rm -rf $WDIR/$PATCHES/*
DIRS=rootfs-skeleton
for i in $(ls woof-CE/woof-code/rootfs-packages/)
do
 DIRS="$DIRS rootfs-packages/$i"
done
for D in $DIRS
do
 FOLDER=woof-CE/woof-code/$D
 cd $WDIR/$FOLDER
 for f in $(find ./ -type f)
 do
 [ -f $COMP_DIR/$f ] && [ "$(diff -u -N $f $COMP_DIR/$f)" != "" ] \
  && diff -u -N $f $COMP_DIR/$f > $WDIR/$PATCHES/$(basename $f).patch
 done
 #exit 0 #Uncomment to check if compared correctly
 cd $WDIR/$PATCHES
 DS="$(echo $D | sed 's/\//\\\//')"
 sed -i "s/\-\-\-\ \.\//\-\-\-\ a\/woof\-code\/$DS\//" *
 if [ "$1" = "sfs" ]; then
  sed -i "s/\+\+\+\ \/initrd\/pup_ro2\/\.\//\+\+\+\ b\/woof\-code\/$DS\//" *
 else
  sed -i "s/\+\+\+\ \/\.\//\+\+\+\ b\/woof\-code\/$DS\//" *
 fi
done
# check init
INITPATH=$(echo "$PUPSFS" | cut -f 2 -d '/' | grep -v sfs)
mkdir -p /tmp/initfs
cd /tmp/initfs
gunzip -c /mnt/home/$INITPATH/initrd.gz | cpio -i
cd $WDIR/woof-CE
diff -u initrd-progs/0initrd/init /tmp/initfs/init > $WDIR/$PATCHES/init.patch
sed -i "s/\-\-\-\ /\-\-\-\ a\//" $WDIR/$PATCHES/init.patch
sed -i "s/\+\+\+\ \/tmp\/initfs/\+\+\+\ b\/initrd\-progs\/0initrd/" $WDIR/$PATCHES/init.patch
rm -rf /tmp/initfs
# Move some patches to folders for easy reviewing
cd $WDIR/$PATCHES
mkdir binary_files SVGs defaults docs running desktop
for f in $( grep ^Binary * | cut -f 1 -d':')
do
  mv $f binary_files/
done
mv *.svg.patch SVGs/
mv default*.patch defaults/
mv *.rules.patch running/
mv {PUPSTATE,BOOTCONFIG,clock,current_month,issue,hosts,hostname,ld.so.conf,resolv.conf,profile}.patch running/
mv *.{htm,html,css,txt}.patch docs/
mv *.html.*.patch docs/
mv *.desktop.patch desktop/
rm -f messages.patch
cd $WDIR

 exit 0 #Uncomment to review if patches are OK FOR woof-CE
rm -f $WDIR/$PATCHES.tar.gz
tar cvzf $PATCHES.tar.gz $PATCHES/
exit 0
