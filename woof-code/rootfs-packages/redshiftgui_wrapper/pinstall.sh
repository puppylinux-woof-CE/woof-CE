#!/bin/sh
if [ "$(pwd)" = '/' ];then
	if grep -qsE 'Exec=redshiftgui$' \
	  usr/share/applications/redshiftgui.desktop; then
		sed -i 's/Exec=redshiftgui$/&.sh/' usr/share/applications/redshiftgui.desktop
	fi
fi
