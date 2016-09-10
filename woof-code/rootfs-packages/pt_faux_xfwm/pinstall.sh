[ -f etc/DISTRO_SPECS ] && . etc/DISTRO_SPECS
XF=xfwallpaper.svg
(
cd usr/share/backgrounds

if [ -f "${DISTRO_FILE_PREFIX}-wall1.svg" ];then
	mv -f $XF oxfwallpaper.svg
	cp -af "${DISTRO_FILE_PREFIX}-wall1.svg" $XF
fi
)
	
