#!/bin/sh
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html).
#called from /usr/local/petget/downloadpkgs.sh.
#passed param is the path and name of the downloaded package.

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
	*.deb) dpkg-deb --contents "$DLPKG" &>/dev/null ; exit $? ;;
	*.t[gx]z|*.tar.*) tar -tf "$DLPKG" &>/dev/null ; exit $? ;;
esac

### END ###