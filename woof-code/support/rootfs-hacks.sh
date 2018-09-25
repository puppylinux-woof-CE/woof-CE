#!/bin/sh

SR=
[ "$1" ] && SR="$1" #SYSROOT

# xmessage symlink
if [ ! -L ${SR}/usr/bin/xmessage ] ; then
	ln -snfv gxmessage ${SR}/usr/bin/xmessage
fi

# rxvt-unicode symlink
if [ ! -e ${SR}/usr/bin/rxvt-unicode ] && [ -f ${SR}/usr/bin/urxvt ] ; then
	ln -snfv urxvt ${SR}/usr/bin/rxvt-unicode
fi

# zenity symlink
if [ ! -L ${SR}/usr/bin/zenity ] && [ -f ${SR}/usr/bin/yad ] ; then
	ln -snfv yad ${SR}/usr/bin/zenity
fi

# python symlink
if [ ! -e ${SR}/usr/bin/python ] ; then
	[ -f ${SR}/usr/bin/python2.7 ] && ln -snfv python2.7 ${SR}/usr/bin/python
	[ -f ${SR}/usr/bin/python2.6 ] && ln -snfv python2.6 ${SR}/usr/bin/python
fi

# python3 symlink
if [ ! -e ${SR}/usr/bin/python3 ] ; then
	[ -f ${SR}/usr/bin/python3.4 ] && ln -snfv python3.4 ${SR}/usr/bin/python3
	[ -f ${SR}/usr/bin/python3.5 ] && ln -snfv python3.5 ${SR}/usr/bin/python3
	[ -f ${SR}/usr/bin/python3.6 ] && ln -snfv python3.6 ${SR}/usr/bin/python3
	[ -f ${SR}/usr/bin/python3.7 ] && ln -snfv python3.7 ${SR}/usr/bin/python3
fi

# fixes for gtkdialog
if [ -e ${SR}/usr/sbin/gtkdialog ];then
	[ ! -e ${SR}/usr/sbin/gtkdialog3 ] && ln -snfv gtkdialog ${SR}/usr/sbin/gtkdialog3
	[ ! -e ${SR}/usr/sbin/gtkdialog4 ] && ln -snfv gtkdialog ${SR}/usr/sbin/gtkdialog4
else # ${SR}/usr/sbin/gtkdialog does not exist
	[ -e ${SR}/usr/sbin/gtkdialog3 ] && ln -snfv gtkdialog3 ${SR}/usr/sbin/gtkdialog
	[ -e ${SR}/usr/sbin/gtkdialog4 ] && ln -snfv gtkdialog4 ${SR}/usr/sbin/gtkdialog
fi

# squashfs: assume 3 kernel
if [ ! -e ${SR}/usr/sbin/mksquashfs ] ; then
	[ -e ${SR}/usr/sbin/mksquashfs4 ] && ln -snf mksquashfs4 ${SR}/usr/sbin/mksquashfs
fi
if [ ! -e ${SR}/usr/sbin/unsquashfs ] ; then
	[ -e ${SR}/usr/sbin/unsquashfs4 ] && ln -snf unsquashfs4 ${SR}/usr/sbin/unsquashfs
fi
if [ -e ${SR}/usr/bin/mksquashfs ] && [ ! -e ${SR}/usr/bin/mksquashfs4 ] ; then
	ln -snf mksquashfs ${SR}/usr/bin/mksquashfs4
fi
if [ -e ${SR}/usr/bin/unsquashfs ] && [ ! -e ${SR}/usr/bin/unsquashfs4 ] ; then
	ln -snf unsquashfs ${SR}/usr/bin/unsquashfs4
fi

# /usr/bin/env symlink
if [ ! -e ${SR}/usr/bin/env ] && [ -e ${SR}/bin/env ] ; then
	ln -snf /bin/env ${SR}/usr/bin/env
fi

# /usr/bin/expr symlink
if [ ! -e ${SR}/usr/bin/expr ] && [ -e ${SR}/bin/expr ] ; then
	ln -snf /bin/expr ${SR}/usr/bin/expr
fi

# fix Grub4DosConfig.desktop
sed -i -e 's%^Categories=.*%Categories=X-SetupUtility%' \
	-e 's%^Icon=.*%Icon=/usr/share/pixmaps/puppy/install.svg%' \
	${SR}/usr/share/applications/Grub4DosConfig.desktop
