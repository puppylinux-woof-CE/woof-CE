#!/bin/sh

echo
echo "Executing ${0}.."

SR=
[ "$1" ] && SR="$1" #SYSROOT

# xmessage symlink
if [ -x ${SR}/usr/bin/gxmessage ] && [ ! -L ${SR}/usr/bin/xmessage ] ; then
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
if [ -f ${SR}/etc/mke2fs.conf ] ; then
	sed -i 's/64bit,//g' ${SR}/etc/mke2fs.conf
fi

# fix cups for samba, got this code from /usr/sbin/cups_shell...
# fixes from rcrsn51 for samba printing...
if [ -f ${SR}/etc/cups/snmp.conf ] ; then
	if [ "`stat -c %U%G ${SR}/etc/cups/snmp.conf | grep 'UNKNOWN'`" != "" ] ; then
		chown root:nobody ${SR}/etc/cups/snmp.conf
	fi
fi
for i in ${SR}/usr/lib/cups ${SR}/usr/lib64/cups
do
	if [ ! -d $i ] ; then
		continue
	fi
	LIBCUPS=$i
	if [ -d ${LIBCUPS}/backend ] ; then
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
		chmod 500 ${LIBCUPS}/backend/*
	fi
	if [ -d ${LIBCUPS}/filter ] ; then
		chmod 0755 ${LIBCUPS}/filter
	fi
done
[ -f ${SR}/etc/opt/samba/smb.conf ] && chmod 755 ${SR}/etc/opt/samba/smb.conf #need world-readable.
[ -f ${SR}/etc/samba/smb.conf ] && chmod 755 ${SR}/etc/samba/smb.conf #need world-readable.

# fix permissions
[ -e ${SR}/etc/gshadow ] && chmod 600 ${SR}/etc/gshadow
[ -e ${SR}/etc/shadow ]  && chmod 600 ${SR}/etc/shadow
[ -e ${SR}/etc/sudoers ] && chmod 640 ${SR}/etc/sudoers
[ -e ${SR}/tmp ] && chmod 1777 ${SR}/tmp
[ -e ${SR}/var ] && chmod 777 ${SR}/var

# ensure application_x-bittorrent is assigned to defaulttorrent..
if [ -f ${SR}/etc/xdg/rox.sourceforge.net/MIME-types/application_x-bittorrent ] ; then
	if ! grep -q defaulttorrent ${SR}/etc/xdg/rox.sourceforge.net/MIME-types/application_x-bittorrent ; then
		echo '#!/bin/sh
exec defaulttorrent "$@"
' > ${SR}/etc/xdg/rox.sourceforge.net/MIME-types/application_x-bittorrent
		chmod +x ${SR}/etc/xdg/rox.sourceforge.net/MIME-types/application_x-bittorrent
	fi
fi

# enable xorg mouse keys
for i in ${SR}/usr/share/X11/xkb/symbols/pc ${SR}/etc/X11/xkb/symbols/pc ; do
	[ -f $i ] || continue
	sed -i 's%key <NMLK>.*Num_Lock.*%key <NMLK> { [ Num_Lock, Pointer_EnableKeys ] };%' $i
	# grep 'key <NMLK>.*Num_Lock' /usr/share/X11/xkb/symbols/pc
done

# workaround for hardcoded rox everywhere - allow more default file managers..
if [ -f ${SR}/usr/local/bin/rox ] && [ ! -L ${SR}/usr/local/bin/rox ] ; then
	mv -f ${SR}/usr/local/bin/rox ${SR}/usr/local/bin/roxfiler
	ln -sv defaultfilemanager ${SR}/usr/local/bin/rox
fi
if [ -f ${SR}/usr/share/applications/ROX-Filer-file-manager.desktop ] ; then
	sed -i 's|Exec=rox.*|Exec=roxfiler|' ${SR}/usr/share/applications/ROX-Filer-file-manager.desktop
fi

# debian's procps has a wrong pkill symlink
if [ -L ${SR}/usr/bin/pkill ] ; then
	if [ "`readlink ${SR}/usr/bin/pkill`" = "pgrep" ] ; then
		ln -snfv ../../bin/busybox ${SR}/usr/bin/pkill
	fi
fi

# ensure X is a symlink to Xorg
if [ -f ${SR}/usr/bin/Xorg ] && [ ! -L ${SR}/usr/bin/X ] ; then
	ln -snfv Xorg ${SR}/usr/bin/X
fi

# need a working wget
if [ -f ${SR}/etc/wgetrc ] ; then
	if ! grep -q "check_certificate = off" ${SR}/etc/wgetrc ; then
		echo "check_certificate = off
	#ca_certificate = /etc/ssl/certs/ca-certificates.crt
	continue = on" >> ${SR}/etc/wgetrc
	fi
fi

# fix some apps to work without root
for i in usr/bin/xsane usr/bin/xchat usr/bin/hexchat usr/bin/amule
do
	if [ -f ${SR}/${i} ] ; then
		sed -i "s/getuid/getpid/g" ${SR}/${i}
	fi
done

# delete files
[ -e ${SR}/etc/profile.d ] && rm -f ${SR}/etc/profile.d/*.csh* # slackware: just in case any got through, remove c-shell scripts...
[ -e ${SR}/install ] && rm -rf ${SR}/install #maybe stray /install dir from slackware pkgs...
[ -e ${SR}/etc/cron.daily ] && rm -rf ${SR}/etc/cron.daily #slackware pkg may create this...
[ -e ${SR}/puninstall.sh ] && rm -f ${SR}/puninstall.sh
[ -e ${SR}/pet.specs ] && rm -f ${SR}/pet.specs
[ -d ${SR}/usr/share/xine/libxine1/fonts ] && rm -rf ${SR}/usr/share/xine/libxine1/fonts
[ -f ${SR}/usr/share/applications/qv4l2.desktop ] && rm ${SR}/usr/share/applications/qv4l2.desktop #slackware

# in puppy 'run' is a relative link to 'tmp'
if [ -d ${SR}/run ] && [ ! -L ${SR}/run ] ; then
	rm -rf ${SR}/run
	ln -sv tmp ${SR}/run
fi

# gutenprint_FIXUPHACK
if [ -d ${SR}/usr/share/gutenprint/samples ] ; then
	rm -rf ${SR}/usr/share/gutenprint/samples
fi

# normalize_FIXUPHACK
if [ -f ${SR}/usr/bin/normalize-audio ] && [ ! -f ${SR}/usr/bin/normalize ] ; then
	ln -s normalize-audio ${SR}/usr/bin/normalize
fi

# -pup scripts replace binaries which become -FULL apps ..
find ${SR}/bin ${SR}/sbin -name '*-pup' 2>/dev/null | \
while read i ; do
	app=${i%-pup} #remove -pup suffix
	if [ -f $app ] ; then
		[ -h $app ] && continue
		mv -fv $app ${app}-FULL
		mv -fv $i ${app}
	fi
done

# future: -FULL apps might become the standard apps
for i in bin/df bin/mount bin/ps bin/umount sbin/losetup
do
	if [ -e ${SR}/$i ] && [ ! -e ${SR}/${i}-FULL ] ; then
		ln -sv ${i##*/} ${SR}/${i}-FULL
	fi
done

# upupdd: ptheme calls killall and killall fails for some reason
# need busybox killall (debian: psmisc, slackware: procps(-ng))
if [ -e ${SR}/bin/killall ] && [ ! -L ${SR}/bin/killall ] ; then
	mv -fv ${SR}/bin/killall ${SR}/bin/killall-FULL
	ln -snfv /bin/busybox ${SR}/bin/killall
fi
if [ -e ${SR}/usr/bin/killall ] && [ ! -L ${SR}/usr/bin/killall ] ; then
	mv -fv ${SR}/usr/bin/killall ${SR}/usr/bin/killall-FULL
	ln -snfv /bin/busybox ${SR}/usr/bin/killall
fi

# need busybox su - spot
# ubuntu tarh-cosmic: 'login' pkg
# ubuntu disco+     : 'util-linux' pkg
if [ -e ${SR}/bin/su ] && [ ! -L ${SR}/bin/su ] ; then
	mv -fv ${SR}/bin/su ${SR}/bin/su-FULL
	ln -snfv /bin/busybox ${SR}/bin/su
fi

# need to enforce pterminfo: xterm -- see /etc/profile
if [ -d ${SR}/usr/share/terminfox ] ; then
	rm -rf ${SR}/usr/share/terminfo
	mv -f ${SR}/usr/share/terminfox ${SR}/usr/share/terminfo
fi

# slackware doesn't have libtinfo.so.5
if [ -e ${SR}/lib/libncurses.so.5 ] && [ ! -e ${SR}/lib/libtinfo.so.5 ] ; then
	ln -sv /lib/libncurses.so.5 ${SR}/lib/libtinfo.so.5
fi
if [ -e ${SR}/lib64/libncurses.so.5 ] && [ ! -e ${SR}/lib64/libtinfo.so.5 ] ; then
	ln -sv /lib64/libncurses.so.5 ${SR}/lib64/libtinfo.so.5
fi

echo ----

if [ -f ${0}_libs ] ; then
	exec ${0}_libs $@
fi

### END ###