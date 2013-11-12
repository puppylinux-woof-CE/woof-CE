#!/bin/sh
#2007 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html)
#make the pup_save.2fs file bigger.
#v412 /etc/DISTRO_SPECS, renamed pup_xxx.sfs, pup_save.2fs etc.
#v555 pup files renamed to woofr555.sfs, woofsave.2fs.
#100913 simplified filenames, minor update of comments.
#120202 rodin.s: internationalized.
#120323 partial replace 'xmessage' with 'pupmessage'.
#130715 some translation fixes.

export TEXTDOMAIN=resizepfile.sh
export TEXTDOMAINDIR=/usr/share/locale
export OUTPUT_CHARSET=UTF-8
eval_gettext () {
  local myMESSAGE=$(gettext "$1")
  eval echo \"$myMESSAGE\"
}

#variables created at bootup by /initrd/usr/sbin/init...
. /etc/rc.d/PUPSTATE
. /etc/DISTRO_SPECS #v412

#find out what modes use a ${DISTRO_FILE_PREFIX}save.2fs file...
CANDOIT="no"
case $PUPMODE in
 "12") #${DISTRO_FILE_PREFIX}save.3fs (pup_rw), nothing on pup_ro1, ${DISTRO_PUPPYSFS} (pup_ro2).
  PERSISTMNTPT="/initrd/pup_rw"
  CANDOIT="yes"
  ;;
 "13") #tmpfs (pup_rw), ${DISTRO_FILE_PREFIX}save.3fs (pup_ro1), ${DISTRO_PUPPYSFS} (pup_ro2).
  PERSISTMNTPT="/initrd/pup_ro1"
  CANDOIT="yes"
  ;;
esac

 if [ "$CANDOIT" != "yes" ];then
  pupmessage -center -bg "#ffc0c0" -title "$(gettext 'Resize personal storage file: ERROR')" "$(gettext 'Sorry, Puppy is not currently using a personal persistent')
$(gettext 'storage file. If this is the first time that you booted')
$(gettext 'Puppy, say from a live-CD, you are currently running')
$(gettext 'totally in RAM and you will be asked to create a personal')
$(gettext 'storage file when you end the session (shutdown the PC or')
`eval_gettext \"reboot). Note, the file will be named \\\${DISTRO_FILE_PREFIX}save.2fs and\"`
$(gettext 'will be created in a place that you nominate.')
$(gettext 'If you have installed Puppy to hard drive, or installed')
$(gettext 'such that personal storage is an entire partition, then')
`eval_gettext \"you will not have a \\\${DISTRO_FILE_PREFIX}save.2fs file either.\"`
$(gettext 'Press OK to exit...')"
  exit
 fi

[ ! "$PUPSAVE" ] && exit #precaution
[ ! "$PUP_HOME" ] && exit #precaution.

SAVEFS="`echo -n "$PUPSAVE" | cut -f 2 -d ','`"
SAVEPART="`echo -n "$PUPSAVE" | cut -f 1 -d ','`"
SAVEFILE="`echo -n "$PUPSAVE" | cut -f 3 -d ','`"
NAMEPFILE="`basename $SAVEFILE`"

HOMELOCATION="/initrd${PUP_HOME}${SAVEFILE}"
SIZEFREE=`df -m | grep "$PERSISTMNTPT" | tr -s " " | cut -f 4 -d " "` #free space in ${DISTRO_FILE_PREFIX}save.3fs
ACTUALSIZK=`ls -sk $HOMELOCATION | tr -s " " | cut -f 1 -d " "` #total size of ${DISTRO_FILE_PREFIX}save.3fs
if [ ! $ACTUALSIZK ];then
 ACTUALSIZK=`ls -sk $HOMELOCATION | tr -s " " | cut -f 2 -d " "`
fi
ACTUALSIZE=`expr $ACTUALSIZK \/ 1024`
APATTERN="/dev/${SAVEPART} "
PARTFREE=`df -m | grep "$APATTERN" | tr -s " " | cut -f 4 -d " "`


REPORTACTION="$(gettext 'Welcome to the Puppy Resize personal storage file utility!')"

MAINTEXT="`eval_gettext \"Your personal file is \\\$NAMEPFILE, and this contains all of your data,\"`
$(gettext 'configuration files, email, newsgroup cache, history files, installed')
$(gettext 'packages and so on.') 

`eval_gettext \"You have \\\$SIZEFREE Mbytes free space left in \\\$NAMEPFILE,\"`
`eval_gettext \"out of a total size of \\\$ACTUALSIZE Mbytes.\"`

`eval_gettext \"File \\\$NAMEPFILE is actually stored on partition \\\$SAVEPART.\"`
`eval_gettext \"You have \\\$PARTFREE Mbytes space left in \\\$SAVEPART.\"`

$(gettext 'So, you need to make a decision. If you see that you are running')
`eval_gettext \"low on space in \\\$NAMEPFILE, you can make it bigger, but of\"`
`eval_gettext \"course there must be enough space in \\\$SAVEPART.\"`
`eval_gettext \"Note, it was reported on the Forum that \\\$NAMEPFILE should not be\"`
$(gettext 'made bigger than 1.8GB, but I have yet to confirm this limitation.')

$(gettext 'PLEASE NOTE THAT AFTER YOU HAVE CLICKED A BUTTON BELOW,
NOTHING WILL HAPPEN. THE RESIZING WILL HAPPEN AT REBOOT.')

`eval_gettext \"Press a button to make \\\$NAMEPFILE bigger by that amount...\"`
$(gettext '(note, this is one-way, you cannot make it smaller)')"

BUTTONS="+16M:15,+32M:14,+64M:10,+128M:11,+256M:12,+512M:13,$(gettext 'EXIT'):19"


xmessage -center -bg "#c0ffff" -title "$(gettext 'Resize personal storage file')" -buttons "$BUTTONS" -file -<<MSG1
$REPORTACTION

$MAINTEXT
MSG1

REPLYX=$?

KILOBIG=
case ${REPLYX} in
   15)# 16M
    KILOBIG=16384
   ;;
   14)# 32M
    KILOBIG=32768
   ;;
   10)# 64M
    KILOBIG=65536
   ;;
   11)# 128M
    KILOBIG=131072
   ;;
   12)# 256M
    KILOBIG=262144
   ;;
   13)# 512M
    KILOBIG=524288
   ;;
   *)
    exit
   ;;
esac

echo -n "$KILOBIG" > /initrd${PUP_HOME}/pupsaveresize.txt

pupmessage -center -bg "orange" -title "$(gettext 'Resize personal storage file')" "$(eval_gettext 'Okay, you have chosen to increase ${NAMEPFILE} by ${KILOBIG} Kbytes, however as the file is currently in use, it will happen at reboot.')

$(gettext 'Technical notes:')
$(eval_gettext 'The required size increase has been written to file pupsaveresize.txt, in partition ${SAVEPART} (currently mounted on /mnt/home).')
$(gettext 'File pupsaveresize.txt will be read at bootup and the resize performed then pupsaveresize.txt will be deleted.')

$(eval_gettext 'WARNING: If you have multiple ${DISTRO_FILE_PREFIX}save files, be sure to select the same one when you reboot.')

$(gettext 'You can keep using Puppy. The change will only happen at reboot.')
$(gettext 'Click OK to exit...')"

###END###

#notes:
#  dd if=/dev/zero bs=1k count=$KILOBIG | tee -a $HOMELOCATION > /dev/null
