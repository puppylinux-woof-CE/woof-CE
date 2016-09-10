[ -f etc/DISTRO_SPECS ] && . etc/DISTRO_SPECS
POP=Sky.svg
(
cd usr/share/backgrounds
[ -f "$POP" ] || POP=`ls|tail -1`
cp -af $POP pop.svg
if [ -f "${DISTRO_FILE_PREFIX}-wall8.svg" ];then
	mv -f $POP opop.svg
	cp -af "${DISTRO_FILE_PREFIX}-wall8.svg" pop.svg
fi
)
