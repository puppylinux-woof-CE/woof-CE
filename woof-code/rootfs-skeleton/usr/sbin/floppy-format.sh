#!/bin/sh
#Format floppy disks
#Copyright (c) Barry Kauler 2004 www.goosee.com/puppy
#2007 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html)
#130517 BK: code improved and internationalized.

export TEXTDOMAIN=floppy-format
export OUTPUT_CHARSET=UTF-8

zapfloppy()
{
 # Puppy will only allow 1440, 1680K and 1760K capacities.
 ERR0=1
 while [ $ERR0 -ne 0 ];do
  pwMSG="$(gettext 'Low-level formatting disk with this capacity:') ${1} Kbyte
$(gettext 'Please wait...')"
  /usr/lib/gtkdialog/box_splash -close never -fontsize large -text "${pwMSG}" &
  pwID=$!
  fdformat /dev/fd0u$1
  ERR0=$?
  sync
  #killall xmessage
  pupkill $pwID
  if [ $ERR0 -ne 0 ];then
   xmessage -bg "#ffe0e0" -name "loformat" -title "$(gettext 'Puppy Low-level Formatter')" -center -buttons "$(gettext 'Try again')":20,"$(gettext 'QUIT')":10 -file -<<XMSG
$(gettext 'ERROR low-level formatting disk.')
$(gettext 'Is the write-protect tab closed?')
XMSG

   AN0=$?
   if [ $AN0 -eq 10 ];then
    ERR0=0
   fi
   if [ $AN0 -eq 0 ];then
    ERR0=0
   fi
   if [ $AN0 -eq 1 ];then
    ERR0=0
   fi
  else
   INTROMSG="
$(gettext '\ZbSUCCESS!\ZB')
$(gettext 'Now you should press the \ZbMsdos/vfat filesystem\ZB button.')"
  fi
 done
}

fsfloppy()
{
echo "$(gettext 'Creating msdos filesystem on the disk...')"
ERR1=1
while [ ! $ERR1 -eq 0 ];do
 pwMSG="$(gettext 'Creating msdos/vfat filesystem on floppy disk')
$(gettext 'Please wait...')"
 /usr/lib/gtkdialog/box_splash -close never -fontsize large -text "${pwMSG}" &
 pwID=$!
 mkfs.msdos -c /dev/fd0u$1
 #mformat -f $1 a:
 #mbadblocks a:
 ERR1=$?
 #killall xmessage
 pupkill $pwID
 if [ $ERR1 -ne 0 ];then
  xmessage -bg "#ffe0e0" -name "msdosvfat" -title "$(gettext 'Floppy msdos/vfat filesystem')" -center \
  -buttons "$(gettext 'Try again')":20,"$(gettext 'QUIT')":10 -file -<<XMSG
$(gettext 'ERROR creating msdos/vfat filesystem on the floppy disk.')
$(gettext 'Is the write-protect tab closed?')
XMSG

  AN0=$?
  if [ $AN0 -eq 10 ];then
   ERR1=0
  fi
  if [ $AN0 -eq 0 ];then
   ERR1=0
  fi
  if [ $AN0 -eq 1 ];then
   ERR1=0
  fi
 else
  INTROMSG="
$(gettext '\ZbSUCCESS!\ZB')
$(gettext 'The floppy disk is now ready to be used. Use the Puppy Drive Mounter to mount it. Or, click the floppy-disk icon on the desktop.')
$(gettext 'First though, press \ZbEXIT\ZB to get out of here...')"
 fi
done
sync
echo "$(gettext '...done.')"
echo " "
}

INTROMSG="$(gettext '\ZbWELCOME!\ZB')
$(gettext 'The Puppy Floppy Formatter only formats floppies with 1440 Kbyte capacity and with the msdos/vfat filesystem, for interchangeability with Windows.')

$(gettext 'You only need to low-level format if the disk is formatted with some other capacity, or it is corrupted. You do not have to low-level format a new disk, but may do so to check its integrity.')
$(gettext 'A disk is NOT usable if it is only low-level formatted: it also must have a filesystem, so this must always be the second step.')
$(gettext 'Doing step-2 only, that is, creating a filesystem on a disk, is also a method for wiping any existing files.')"

#big loop...
while :; do

 MNTDMSG=" "
 mount | grep "/dev/fd0" > /dev/null 2>&1
 if [ $? -eq 0 ];then #=0 if string found
  CURRENTMNT="`mount | grep "/dev/fd0" | cut -f 3 -d ' '`"
  sync
  umount "$CURRENTMNT" #/mnt/floppy
  if [ $? -ne 0 ];then
   MNTDMSG="
$(gettext 'Puppy found a floppy disk already mounted in the drive, but is not able to unmount it. The disk must be unmounted now. Please click the \Zbclose box\ZB on the floppy-disk icon on the desktop, or use the Puppy Drive Mounter (click \Zbmount\ZB icon at top of screen) to unmount the floppy disk. DO THIS FIRST!')"
  else
   MNTDMSG="
$(gettext 'Puppy found that the floppy disk was mounted, but has now unmounted it. Now ok to format disk.')"
  fi
 fi

 pressMSG="$(gettext 'Press a button:')"
 pupdialog --colors --background '#e0ffe0' --title "$(gettext 'Puppy Floppy Formatter')" --extra-button --yes-label "$(gettext 'Low-level Format')" --no-label "$(gettext 'EXIT')" --extra-label "$(gettext 'Msdos/vfat filesystem')" --yesno "${INTROMSG}
${MNTDMSG}
${pressMSG}" 0 0

 ANS=$?
 
 case $ANS in
  0) #low-level format
   zapfloppy 1440
  ;;
  3) #vfat
   fsfloppy 1440
  ;;
  1) #exit
   break
  ;;
  *)
   break
  ;; 
 esac

done

###END###
