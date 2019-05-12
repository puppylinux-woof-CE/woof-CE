#!/bin/sh
#rootfs-skeleton post-install script
#

#exec 2>/dev/null # comment to enable debug output
echo "Configuring Puppy skeleton..."
# tasks that used to be done by merge2out: cleanup, set permissions, missing dirs

# cleanup
find . -name "*MARKER" -delete

# set permissions and owners as needed
mknod ./dev/null c 1 3
chmod 666 ./dev/null
chmod 1777 tmp archive
chown 0755 usr/lib/cups/backend usr/lib/cups/filters
chmod 0500 usr/lib/cups/backend/*

# symlinks
rm -rf run; ln -s tmp run # make /run is symlink to /tmp, always
ln -sf bash bin/sh        # ensure that default shell is *always* bash
! [ -f usr/bin/rxvt ] && ln -sf xterm usr/bin/rxvt

# last few steps
# update dynamic databases we didn't setup earlier
echo MIME database setup
chroot . /usr/bin/update-mime-database /usr/share/mime 2>/dev/null
echo Gdk pixbuf loaders setup
chroot . /usr/bin/gdk-pixbuf-query-loaders --update-cache 2>/dev/null
chroot . /$(echo usr/lib/*/*/gdk-pixbuf-query-loaders) --update-cache 2>/dev/null
echo Pango modules setup
chroot . /usr/bin/pango-querymodules --update-cache 2>/dev/null
echo Create udev hardware database
chroot . /sbin/udevadm hwdb --update 2>/dev/null

# tell ROX to use puppy's icons, if rox-mime-data is installed
if ! [ -x usr/local/apps/ROX-Filer/ROX-Filer ] && 
   [ -d usr/local/apps/ROX-Filer/ROX/MIME ]; then
	ROXMIME=$(find . -name MIME | grep -v usr/local/apps | grep ROX)
	if [ "$ROXMIME" ]; then
		rm -rf $ROXMIME
		ln -s /usr/local/apps/ROX-Filer/ROX/MIME $ROXMIME
	fi
fi

# create puppy icons
source=usr/local/lib/X11/themes/StandardSvg
target=usr/local/lib/X11/pixmaps
for p in $(ls $source); do
	chroot . /usr/bin/rsvg-convert -w 48 -h 48 /$source/$p > $target/${p%.svg}48.png
done

# rename -puppy scripts to original names
find . -name "*-puppy" | grep -vE "set-time-for-puppy" | while read -r p; do
	pp=${p%-puppy}
	[ -e $pp ] && mv $pp ${pp}-FULL
	mv $p $pp
done

exit

# ======= Original code, left as reference for later until migration is complete ============

#post-install script.
#Puppy Linux
#assume current directory is rootfs-complete, which has the final filesystem.
#this script is similar to the post-install scripts of the window managers.
#Keywords are located in the Help page and the lines uncommented.
#DISTRO_VERSION, DISTRO_NAME are global variables visible here.
#110422 DISTRO_VERSION variable now has dotted format. note, also now using full dotted version# in puppy filenames.
#120225 create symlink release-notes.htm to actual release-notes file. NO.
#120225 backup doc files, refer /usr/sbin/indexgen.sh.
#120818 now have /etc/xdg in Woof, taken out of xdg_puppy PET, relocated pinstall.sh to here.
#132211 removed icewm template from default, who uses that anyway?

WKGDIR="`pwd`"

echo "Configuring Puppy skeleton..."

#cleanup...
rm -f /tmp/fbvideomode.txt

echo "Configuring Puppy Help page..."

#refer /usr/sbin/indexgen.sh...
cp -f usr/share/doc/index.html.top usr/share/doc/index.html.top-raw #120225
cp -f usr/share/doc/index.html.bottom usr/share/doc/index.html.bottom-raw #120225
cp -f usr/share/doc/home.htm usr/share/doc/home-raw.htm #120225

cutDISTRONAME="`echo -n "$DISTRO_NAME" | cut -f 1 -d ' '`"
cPATTERN="s/cutDISTRONAME/${cutDISTRONAME}/g"
RIGHTVER="$DISTRO_VERSION"
PUPPYDATE="`date | tr -s " " | cut -f 2,6 -d " "`"
dPATTERN="s/PUPPYDATE/${PUPPYDATE}/g"

echo "Writing version number and distro name and date to Help page..."
PATTERN1="s/RIGHTVER/${RIGHTVER}/g"
PATTERN2="s/DISTRO_VERSION/${DISTRO_VERSION}/g"
nPATTERN="s/DISTRO_NAME/${DISTRO_NAME}/g"
sed -i -e "$PATTERN1" -e "$PATTERN2" -e "$nPATTERN" -e "$dPATTERN" -e "$cPATTERN" usr/share/doc/index.html.top
sed -i -e "$PATTERN1" -e "$PATTERN2" -e "$nPATTERN" -e "$dPATTERN" usr/share/doc/index.html.bottom
#...note, /usr/sbin/indexgen.sh puts these together as index.html (via rc.update and 3builddistro).

echo "Writing distro name to jumping-off page..."
sed -i -e "$nPATTERN" usr/share/doc/home.htm

echo "Creating base release notes..."
if [ ! -e usr/share/doc/release-${cutDISTRONAME}-${DISTRO_VERSION}.htm ];then
 mv -f usr/share/doc/release-skeleton.htm usr/share/doc/release-${cutDISTRONAME}-${DISTRO_VERSION}.htm
 sed -i -e "$PATTERN1" -e "$PATTERN2" -e "$nPATTERN" -e "$dPATTERN" usr/share/doc/release-${cutDISTRONAME}-${DISTRO_VERSION}.htm
#else
# rm -f usr/share/doc/release-skeleton.htm
fi
if [ ! -e usr/share/doc/release-${cutDISTRONAME}-${RIGHTVER}.htm ];then
 ln -s release-${cutDISTRONAME}-${DISTRO_VERSION}.htm usr/share/doc/release-${cutDISTRONAME}-${RIGHTVER}.htm
fi

#ln -snf release-${cutDISTRONAME}-${DISTRO_VERSION}.htm usr/share/doc/release-notes.htm #120225

#echo "The default kernel for Puppy is vmlinuz."
echo -n "vmlinuz" > /tmp/vmlinuzforpup.txt
#note, createpuppy will read this.

#120818 now have /etc/xdg in Woof, taken out of xdg_puppy PET, relocated pinstall.sh to here...
#this code is to fix the icewm menu...
if [ -f ./etc/xdg/templates/_root_.icewm_menu ];then
 if [ "`find ./usr/local/bin ./usr/bin ./usr/sbin ./usr/X11R7/bin -maxdepth 1 -type f -name evilwm`" = "" ];then
  grep -v ' evilwm$' ./etc/xdg/templates/_root_.icewm_menu > /tmp/_root_.icewm_menu
  mv -f /tmp/_root_.icewm_menu ./etc/xdg/templates/
 fi
 if [ "`find ./usr/local/bin ./usr/bin ./usr/sbin ./usr/X11R7/bin -maxdepth 1 -type f -name fluxbox`" = "" ];then
  grep -v ' fluxbox$' ./etc/xdg/templates/_root_.icewm_menu > /tmp/_root_.icewm_menu
  mv -f /tmp/_root_.icewm_menu ./etc/xdg/templates/
 fi
 if [ "`find ./usr/local/bin ./usr/bin ./usr/sbin ./usr/X11R7/bin -maxdepth 1 -type f -name fvwm95`" = "" ];then
  grep -v ' fvwm95$' ./etc/xdg/templates/_root_.icewm_menu > /tmp/_root_.icewm_menu
  mv -f /tmp/_root_.icewm_menu ./etc/xdg/templates/
 fi
 if [ "`find ./usr/local/bin ./usr/bin ./usr/sbin ./usr/X11R7/bin -maxdepth 1 -type f -name jwm`" = "" ];then
  grep -v ' jwm$' ./etc/xdg/templates/_root_.icewm_menu > /tmp/_root_.icewm_menu
  mv -f /tmp/_root_.icewm_menu ./etc/xdg/templates/
 fi
 if [ "`find ./usr/local/bin ./usr/bin ./usr/sbin ./usr/X11R7/bin -maxdepth 1 -type f -name pwm`" = "" ];then
  grep -v ' pwm$' ./etc/xdg/templates/_root_.icewm_menu > /tmp/_root_.icewm_menu
  mv -f /tmp/_root_.icewm_menu ./etc/xdg/templates/
 fi
 if [ "`find ./usr/local/bin ./usr/bin ./usr/sbin ./usr/X11R7/bin -maxdepth 1 -type f -name xfce4-session`" = "" ];then
  grep -v ' xfce4-session$' ./etc/xdg/templates/_root_.icewm_menu > /tmp/_root_.icewm_menu
  mv -f /tmp/_root_.icewm_menu ./etc/xdg/templates/
 fi
fi

#screenshot
TAS=`find usr/bin usr/sbin usr/local/bin -name tas`
SCREENY=`find usr/bin usr/sbin -name 'screeny'`
if [ "$TAS" ];then echo '#!/bin/sh
exec tas' > usr/local/bin/defaultscreenshot
chmod 755 usr/local/bin/defaultscreenshot
SCR=tas
elif [ "$SCREENY" ];then echo '#!/bin/sh
exec screeny' > usr/local/bin/defaultscreenshot
chmod 755 usr/local/bin/defaultscreenshot
SCR=screeny
else
echo '#!/bin/sh
exec mtpaint -s' > usr/local/bin/defaultscreenshot
chmod 755 usr/local/bin/defaultscreenshot
SCR="mtpaint -s"
fi
echo "Setting $SCR as defaultscreenshot app"

# firefox
FF=`find /usr -type d -name 'firefox*'`
if [ "$FF" ];then echo '#!/bin/sh
exec firefox "$@"' > usr/local/bin/defaultbrowser
chmod 755 usr/local/bin/defaultbrowser
echo '#!/bin/sh
exec firefox "$@"' > usr/local/bin/defaulthtmlviewer
chmod 755 usr/local/bin/defaulthtmlviewer
 echo "Setting Firefox as defaultbrowser"
fi
#end#
