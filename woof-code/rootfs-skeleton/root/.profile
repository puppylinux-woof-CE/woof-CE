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

if which Xorg &>/dev/null ; then
   #want to go straight into X on bootup only...
   if [ ! -f /tmp/bootcnt.txt ] ; then
      touch /tmp/bootcnt.txt
      dmesg > /tmp/bootkernel.log
      xwin
   fi
else
   echo -e "\n\\033[1;31mSorry, cannot start X.. Xorg not found. \\033[0;39m"
fi

### END ###
