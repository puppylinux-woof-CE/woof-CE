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
if [ -f ${SR}/usr/share/applications/Grub4DosConfig.desktop ] ; then
	sed -i -e 's%^Categories=.*%Categories=X-SetupUtility%' \
		-e 's%^Icon=.*%Icon=/usr/share/pixmaps/puppy/install.svg%' \
		${SR}/usr/share/applications/Grub4DosConfig.desktop
fi

# (.petbuild) launching dhcpcd / don't need ifplugd...
if [ -e ${SR}/etc/init.d/ifplugd ] ; then
	rm -f ${SR}/etc/init.d/ifplugd
fi

# disable ext4 64bit feature in /etc/mke2fs.conf
#  ...the 'wee' bootloader does not support it
# this should be removed only when a fixed 'wee' version is available for all builds..
if [ -f ${SR}/etc/mke2fs.conf ] ; then
	sed -i 's/64bit,//g' ${SR}/etc/mke2fs.conf
fi

#100524 fix cups for samba, got this code from /usr/sbin/cups_shell...
#fixes from rcrsn51 for samba printing...
if [ -f ${SR}/etc/cups/snmp.conf ] ; then
	if [ "`stat -c %U%G ${SR}/etc/cups/snmp.conf | grep 'UNKNOWN'`" != "" ] ; then
		chown root:nobody ${SR}/etc/cups/snmp.conf
	fi
fi

if [ -e ${SR}/usr/lib/cups ] ; then
	LIBCUPS=${SR}/usr/lib/cups
elif [ -e ${SR}/usr/lib64/cups ] ; then
	LIBCUPS=${SR}/usr/lib64/cups
fi

if [ "$LIBCUPS" ] ; then
	if [ ! -e ${LIBCUPS}/backend/smb ];then
		if [ -f ${SR}/opt/samba/bin/smbspool ] ; then
			ln -s /opt/samba/bin/smbspool ${LIBCUPS}/backend/smb
		fi
		if [ -f ${SR}/usr/bin/smbspool ] ; then
			ln -s /usr/bin/smbspool ${LIBCUPS}/backend/smb
		fi
	fi
	# fix CUPS thanks to jamesbond, shinobar
	# re http://www.murga-linux.com/puppy/viewtopic.php?p=784181#784181
	chmod 0755 ${LIBCUPS}/backend
	chmod 0755 ${LIBCUPS}/filter
	chmod 500 ${LIBCUPS}/backend/*
fi

[ -f ${SR}/etc/opt/samba/smb.conf ] && chmod 755 ${SR}/etc/opt/samba/smb.conf #need world-readable.
[ -f ${SR}/etc/samba/smb.conf ] && chmod 755 ${SR}/etc/samba/smb.conf #need world-readable.

# fix permissions
chmod 600 ${SR}/etc/gshadow
chmod 600 ${SR}/etc/shadow
chmod 640 ${SR}/etc/sudoers
chmod 1777 ${SR}/tmp
chmod 777 ${SR}/var
