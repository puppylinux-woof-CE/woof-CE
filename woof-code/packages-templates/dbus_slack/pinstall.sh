#!/bin/sh

# newer slackware dbus needs system user 'polkitd'
if [ -f etc/dbus-1/system.d/org.freedesktop.PolicyKit1.conf ];then
	if grep -q 'polkitd' etc/dbus-1/system.d/org.freedesktop.PolicyKit1.conf ;then
		chroot . addgroup -g 87 -S polkitd
		sleep 1
		chroot . adduser -S -D -H -h /var/lib/polkit -u 87 -s /bin/false -G polkitd polkitd
		echo "Adding policy kit user"
	fi
fi
