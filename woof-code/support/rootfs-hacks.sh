#!/bin/sh

SR=
[ "$1" ] && SR="$1" #SYSROOT

# xmessage symlink
if [ ! -L ${SR}/usr/bin/xmessage ] && [ -f ${SR}/usr/bin/gxmessage ] ; then
	ln -snfv gxmessage ${SR}/usr/bin/xmessage
fi

# pupmessage symlink
if [ ! -e ${SR}/usr/bin/pupmessage ] && [ -f ${SR}/usr/bin/gxmessage ] ; then
	ln -snfv gxmessage ${SR}/usr/bin/pupmessage
fi

# rxvt-unicode symlink
if [ ! -e ${SR}/usr/bin/rxvt-unicode ] && [ -f ${SR}/usr/bin/urxvt ] ; then
	ln -snfv urxvt ${SR}/usr/bin/rxvt-unicode
fi

# zenity symlink
if [ ! -L ${SR}/usr/bin/zenity ] && [ -f ${SR}/usr/bin/yad ] ; then
	ln -snfv yad ${SR}/usr/bin/zenity
fi
