#120221 moved this code here from /etc/profile, also take 'exec' prefix off call to xwin.

if [ ! -f /usr/bin/X ];then
 #v2.00r1 now support a text-mode-only puppy...
 if [ -f /usr/local/bin/elinks ];then
  if [ ! -f /tmp/bootcnt.txt ];then
   touch /tmp/bootcnt.txt
   #exec /usr/local/bin/elinks file:///usr/share/doc/index.html
   #/usr/local/bin/elinks file:///usr/share/doc/index.html & #110804 110807
   /usr/local/bin/elinks file:///usr/share/doc/index.html
  fi
 else
  echo
  echo "\\033[1;31mSorry, cannot start X. Link /usr/bin/X missing."
  echo -n "(suggestion: type 'xorgwizard' to run the Xorg Video Wizard)"
  echo -e "\\033[0;39m"
 fi
else
 if [ -f /root/.xorgwizard-reenter ];then #130423 see /usr/sbin/xorgwizard-cli  130513 also see init (in initrd)
  xorgwizard-cli
 fi
 #want to go straight into X on bootup only...
 if [ ! -f /tmp/bootcnt.txt ];then
  touch /tmp/bootcnt.txt
  # aplay -N /usr/share/audio/bark.au
  dmesg > /tmp/bootkernel.log
  #exec xwin
  #xwin & #110804 110807
  xwin
 fi
fi
