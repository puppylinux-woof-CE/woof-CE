#!/bin/sh
#post-install script.
#Puppy Linux
#assume current directory is rootfs-complete, which has the final filesystem.

. etc/DISTRO_SPECS

echo "Configuring Puppy skeleton..."
echo "Configuring Puppy Help page..."

cutDISTRONAME="`echo -n "$DISTRO_NAME" | cut -f 1 -d ' '`"
cPATTERN="s/cutDISTRONAME/${cutDISTRONAME}/g"
PUPPYDATE="`date | tr -s " " | cut -f 2,6 -d " "`"
RELEASE_DATE="`date "+%B, %Y"`"
dPATTERN="s/PUPPYDATE/${PUPPYDATE}/g"
rPATTERN="s/RELEASE_DATE/${RELEASE_DATE}/g"
PATTERN2="s/DISTRO_VERSION/${DISTRO_VERSION}/g"
nPATTERN="s/DISTRO_NAME/${DISTRO_NAME}/g"
sed -i -e "$PATTERN2" -e "$nPATTERN" -e "$dPATTERN" -e "$cPATTERN" usr/share/doc/index.html.top
sed -i -e "$PATTERN2" -e "$nPATTERN" -e "$dPATTERN" usr/share/doc/index.html.bottom

(
	cat usr/share/doc/index.html.top
	cat usr/share/doc/index.html.bottom
) > usr/share/doc/index.html

sed -i -e "$nPATTERN" usr/share/doc/home.htm

if [ -f usr/share/doc/release-skeleton.top.htm ] ; then
	(
		sed -e "$PATTERN2" -e "$nPATTERN" -e "$rPATTERN" usr/share/doc/release-skeleton.top.htm
		if [ -f ../../support/release_extras/"${DISTRO_FILE_PREFIX}.htm" ];then
			sed -e "s/DISTRO_VERSION/$DISTRO_VERSION/g" -e "$rPATTERN" \
				../../support/release_extras/"${DISTRO_FILE_PREFIX}.htm"
		fi
		if [ -f ../../support/release_extras/"${DISTRO_FILE_PREFIX}-${DISTRO_COMPAT_VERSION}.htm" ];then
			sed -e "s/DISTRO_VERSION/$DISTRO_VERSION/g" -e "$rPATTERN" \
				../../support/release_extras/"${DISTRO_FILE_PREFIX}-${DISTRO_COMPAT_VERSION}.htm"
		fi
		sed -e "$PATTERN2" -e "$nPATTERN" -e "$rPATTERN" usr/share/doc/release-skeleton.bottom.htm
	) > usr/share/doc/release-${cutDISTRONAME}-${DISTRO_VERSION}.htm
fi

rm -f usr/share/doc/release-skeleton.*

#screenshot
TAS=`find usr/bin usr/sbin usr/local/bin -name tas`
SCREENY=`find usr/bin usr/sbin -name 'screeny'`
if [ "$TAS" ];then
	SCR=tas
elif [ "$SCREENY" ];then
	SCR=screeny
else
	SCR="mtpaint -s"
fi
echo '#!/bin/sh
exec '$SCR > usr/local/bin/defaultscreenshot
chmod 755 usr/local/bin/defaultscreenshot
echo "Setting $SCR as defaultscreenshot app"

### END ###
