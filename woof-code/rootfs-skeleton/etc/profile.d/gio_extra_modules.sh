#!/bin/sh
# not sourcing DISTRO_SPECS...

ZZZ_xARCH="$(uname -m)"

if [ -f /usr/lib/x86_64-linux-gnu/gio/modules/libdconfsettings.so ] && [ "$ZZZ_xARCH" = "x86_64" ]; then
	GIO_EXTRA_MODULES='/usr/lib/x86_64-linux-gnu/gio/modules/'

elif [ -f /usr/lib/i386-linux-gnu/gio/modules/libdconfsettings.so ] && [ "$(echo "$ZZZ_xARCH" | grep "i[3-6]86")" != "" ]; then
	GIO_EXTRA_MODULES='/usr/lib/i386-linux-gnu/gio/modules/'

elif [ -f /usr/lib/arm-linux-gnueabihf/gio/modules/libdconfsettings.so ] && [ "$(echo "$ZZZ_xARCH" | grep "arm")" != "" ]; then
	GIO_EXTRA_MODULES='/usr/lib/arm-linux-gnueabihf/gio/modules/'

elif [ -f /usr/lib/aarch64-linux-gnu/gio/modules/libdconfsettings.so ] && [ "$ZZZ_xARCH" = "aarch64" ]; then
	GIO_EXTRA_MODULES='/usr/lib/aarch64-linux-gnu/gio/modules/'

elif [ -f /usr/lib64/gio/modules/libdconfsettings.so ] ; then
	GIO_EXTRA_MODULES='/usr/lib64/gio/modules/'

elif [ -f /usr/lib/gio/modules/libdconfsettings.so ] ; then
	GIO_EXTRA_MODULES='/usr/lib/gio/modules/'
fi

if [ "$GIO_EXTRA_MODULES" ] ; then
	export GIO_EXTRA_MODULES
fi

unset ZZZ_xARCH
