#!/bin/sh
# not sourcing DISTRO_SPECS...

xARCH="$(uname -m)"

if [ -f /usr/lib64/gio/modules/libdconfsettings.so ] && [ "$(echo "$xARCH" | grep "^.*64")" != "" ]; then
	GIO_EXTRA_MODULES='/usr/lib64/gio/modules/'
elif [ -f /usr/lib/i386-linux-gnu/gio/modules/libdconfsettings.so ] && [ "$(echo "$xARCH" | grep -E "^.*86")" != "" ]; then
	GIO_EXTRA_MODULES='/usr/lib/i386-linux-gnu/gio/modules/'
elif [ -f /usr/lib/arm-linux-gnueabihf/gio/modules/libdconfsettings.so ] && [ "$(echo "$xARCH" | grep -E "^arm*")" != "" ]; then
	GIO_EXTRA_MODULES='/usr/lib/arm-linux-gnueabihf/gio/modules/'
elif [ -f /usr/lib/aarch64-linux-gnu/gio/modules/libdconfsettings.so ] && [ "$(echo "$xARCH" | grep -E "aarch*")" != "" ]; then
	GIO_EXTRA_MODULES='/usr/lib/aarch64-linux-gnu/gio/modules/'
else
   if [ -f /usr/lib/gio/modules/libdconfsettings.so ] ; then
     GIO_EXTRA_MODULES='/usr/lib/gio/modules/'
   fi
fi

if [ "$GIO_EXTRA_MODULES" ] ; then
  export GIO_EXTRA_MODULES
fi

