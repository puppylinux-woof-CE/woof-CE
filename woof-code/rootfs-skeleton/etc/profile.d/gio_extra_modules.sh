#!/bin/sh
# not sourcing DISTRO_SPECS...

if [ -f /usr/lib64/gio/modules/libdconfsettings.so ] && [ "$(uname -m | grep "^.*64")" != "" ]; then
	GIO_EXTRA_MODULES='/usr/lib64/gio/modules/'
elif [ -f /usr/lib/i386-linux-gnu/gio/modules/libdconfsettings.so ] && [ "$(uname -m | grep -E "^.*86")" != "" ]; then
	GIO_EXTRA_MODULES='/usr/lib/i386-linux-gnu/gio/modules/'
elif [ -f /usr/lib/arm-linux-gnueabihf/gio/modules/libdconfsettings.so ] && [ "$(uname -m | grep -E "^arm*")" != "" ]; then
	GIO_EXTRA_MODULES='/usr/lib/arm-linux-gnueabihf/gio/modules/'
elif [ -f /usr/lib/aarch64-linux-gnu/gio/modules/libdconfsettings.so ] && [ "$(uname -m | grep -E "aarch*")" != "" ]; then
	GIO_EXTRA_MODULES='/usr/lib/aarch64-linux-gnu/gio/modules/'
else
   if [ -f /usr/lib/gio/modules/libdconfsettings.so ] ; then
     GIO_EXTRA_MODULES='/usr/lib/gio/modules/'
   fi
fi

if [ "$GIO_EXTRA_MODULES" ] ; then
  export GIO_EXTRA_MODULES
fi

