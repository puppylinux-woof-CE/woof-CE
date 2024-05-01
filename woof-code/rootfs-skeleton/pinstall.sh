#!/bin/sh
#post-install script.
#Puppy Linux
#assume current directory is rootfs-complete, which has the final filesystem.

. etc/DISTRO_SPECS

sed -i "s/Puppy Linux/${DISTRO_NAME}/g" usr/share/backgrounds/*.svg
# take some pixels off for better alignment for 431.svg
for WALL in usr/share/backgrounds/431*svg usr/share/backgrounds/buntoo.svg usr/share/backgrounds/Emerald.svg ; do
	if [ -e "$WALL" ];then
		XVAL=872.666
		P="Puppy Linux"
		if [ $((${#DISTRO_NAME} - ${#P})) -gt 0 ];then
			VAL=$((${#DISTRO_NAME} - ${#P}))
			VAL=${VAL}0
			NVAL=`dc -e"$XVAL $VAL - p"` # ex: if VAL=40 NVAL=832.666
			sed -i "s/$XVAL/$NVAL/" "$WALL"
		fi
	fi
done

echo "Configuring Puppy skeleton..."
echo "Configuring Puppy Help page..."

cutDISTRONAME=${DISTRO_NAME% *}
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

sed -i -e "$nPATTERN" -e "$cPATTERN" -e "$PATTERN2" usr/share/doc/home.htm

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

# if defaultbrowser = mozstart, it probably needs some automatic logic
if grep -q 'mozstart' usr/local/bin/defaultbrowser ; then
	DEFBROWSER=
	if [ -f usr/bin/firefox ] ; then
		DEFBROWSER=firefox
	elif [ -f usr/bin/seamonkey ] ; then
		DEFBROWSER=seamonkey
	elif [ -f usr/bin/palemoon ] ; then
		DEFBROWSER=palemoon
	fi
	if [ "$DEFBROWSER" ] ; then
		echo "Setting $DEFBROWSER as a potentially default web browser"
		echo '#!/bin/ash
exec '${DEFBROWSER}' "$@"
' > usr/local/bin/defaultbrowser
	fi
fi

### END ###
