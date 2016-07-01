#120221 moved this code here from /etc/profile, also take 'exec' prefix off call to xwin.

if which Xorg &>/dev/null ; then

   if [ -f /root/.xorgwizard-reenter ] ; then #130423 see /usr/sbin/xorgwizard-cli  130513 also see init (in initrd)
      xorgwizard-cli
   fi
   #want to go straight into X on bootup only...
   if [ ! -f /tmp/bootcnt.txt ] ; then
      touch /tmp/bootcnt.txt
      dmesg > /tmp/bootkernel.log
      xwin
   fi

else

   if [ -f /usr/local/bin/elinks ] ; then
      #v2.00r1 now support a text-mode-only puppy
      if [ ! -f /tmp/bootcnt.txt ] ; then
         touch /tmp/bootcnt.txt
         /usr/local/bin/elinks file:///usr/share/doc/index.html
      fi
   else
      echo -e "\n\\033[1;31mSorry, cannot start X.. Xorg not found. \\033[0;39m"
   fi

fi

### END ###
