#!/bin/sh

export LANG=C
DLPKG="$1"
case $DLPKG in
	*.pet)
		cp -f "$DLPKG" tempfileonly.pet
		pet2tgz tempfileonly.pet
		RETVAL=$?
		rm -rf tempfileonly.*
		exit $RETVAL
		;;
	*.deb)
		dpkg-deb -c "$DLPKG" >/dev/null 2>&1
		exit $?
		;;
	*.t[gx]z|*.tar.*)
		tar -tf --force-local  "$DLPKG" >/dev/null 2>&1
		exit $?
		;;
esac

### END ###