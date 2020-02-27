#!/bin/sh

export LANG=C
DLPKG="$1"
case $DLPKG in
	*.pet)
		cp -f "$DLPKG" tempfileonly.pet
		pet2tgz tempfileonly.pet
		RETVAL=$?
		rm -rf tempfileonly.*
		;;
	*.deb)
		dpkg-deb -c "$DLPKG" >/dev/null 2>&1
		RETVAL=$?
		;;
	*.t[gx]z|*.tar.*)
		tar --force-local -tf "$DLPKG" >/dev/null 2>&1
		RETVAL=$?
		;;
esac
[ $RETVAL -ne 0 ] && echo "$DLPKG" >> /tmp/petget_proc/pgks_failed_to_install_forced && rm -f $DLPKG
exit $RETVAL
### END ###