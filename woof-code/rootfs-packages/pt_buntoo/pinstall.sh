[ -f etc/DISTRO_SPECS ] && . etc/DISTRO_SPECS
BUN=buntoo.svg
(
cd usr/share/backgrounds

if [ -f "${DISTRO_FILE_PREFIX}-wall2.svg" ];then
	mv -f $BUN obuntoo.svg
	cp -af "${DISTRO_FILE_PREFIX}-wall2.svg" $BUN
fi
)	
