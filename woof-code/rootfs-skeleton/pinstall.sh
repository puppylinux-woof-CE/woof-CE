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

echo "Writing distro name to jumping-off page..."
sed -i -e "$nPATTERN" usr/share/doc/home.htm

echo "Creating base release notes..."
if [ ! -e usr/share/doc/release-${cutDISTRONAME}-${DISTRO_VERSION}.htm ];then
	mv -f usr/share/doc/release-skeleton.htm usr/share/doc/release-${cutDISTRONAME}-${DISTRO_VERSION}.htm
	sed -i -e "$PATTERN2" -e "$nPATTERN" -e "$rPATTERN" usr/share/doc/release-${cutDISTRONAME}-${DISTRO_VERSION}.htm
fi

# write extra stuff for release notes
if [ -f ../../support/release_extras/"${DISTRO_FILE_PREFIX}.htm" ];then
	echo "Customising ${cutDISTRONAME}-${DISTRO_VERSION}.htm"
	[ -f /tmp/release.htm ] && rm /tmp/release.*m
	ctrl=0
	while read htmline;do
		if [ $ctrl -lt 45 ];then # must be updated if the skeleton released notes are altered
			echo  "$htmline" >> /tmp/release.htm
		else
			echo  "$htmline" >> /tmp/release.bottom
		fi
		ctrl=$(($ctrl + 1))
	done < usr/share/doc/release-${cutDISTRONAME}-${DISTRO_VERSION}.htm
	cat "../../support/release_extras/${DISTRO_FILE_PREFIX}.htm" >> /tmp/release.htm
	sed -i -e "s/DISTRO_VERSION/$DISTRO_VERSION/g" -e "$rPATTERN" /tmp/release.htm
	cat /tmp/release.bottom >> /tmp/release.htm
	cp -af /tmp/release.htm usr/share/doc/release-${cutDISTRONAME}-${DISTRO_VERSION}.htm
fi

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
