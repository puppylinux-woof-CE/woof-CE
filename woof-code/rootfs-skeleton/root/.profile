#120221 moved this code here from /etc/profile, also take 'exec' prefix off call to xwin.

mkdir -p /tmp/services
(
	echo "USER=$(id -un)"
	echo "USER_ID=$(id -u)"
	echo "USER_GROUP=$(id -gn)"
	echo "USER_GROUP_ID=$(id -g)"
	echo "LANG='${LANG}'"
	echo "HOME='${HOME}'"
	echo "PATH='${PATH}'"
) > /tmp/services/user_info

if command -v startlabwc >/dev/null 2>&1 ; then
	if [ ! -f /tmp/bootcnt.txt ] ; then
		touch /tmp/bootcnt.txt
		startlabwc
	else
		/usr/sbin/pm13 cli
	fi
elif command -v Xorg >/dev/null 2>&1 ; then
	#want to go straight into X on bootup only...
	if [ ! -f /tmp/bootcnt.txt ] ; then
		touch /tmp/bootcnt.txt
		dmesg > /tmp/bootkernel.log
		xwin
	else
		/usr/sbin/pm13 cli
	fi
else
	/usr/sbin/pm13 cli
fi

### END ###
