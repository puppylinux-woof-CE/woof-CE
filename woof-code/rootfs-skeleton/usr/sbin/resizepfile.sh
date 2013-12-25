#!/bin/sh
#2007 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html)
#make the pup_save.2fs file bigger.
#v412 /etc/DISTRO_SPECS, renamed pup_xxx.sfs, pup_save.2fs etc.
#v555 pup files renamed to woofr555.sfs, woofsave.2fs.
#100913 simplified filenames, minor update of comments.
#120202 rodin.s: internationalized.
#120323 partial replace 'xmessage' with 'pupmessage'.
#130715 some translation fixes.
#131223 gtkdialog

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
/usr/lib/gtkdialog/box_ok "$(gettext 'Resize personal storage file')" error "<b>$(gettext "Sorry, Puppy is not currently using a personal persistent storage file.")</b>" " " "$(gettext "If this is the first time that you booted Puppy, say from a live-CD, you are currently running totally in RAM and you will be asked to create a personal storage file when you end the session (shutdown the PC or reboot). Note, the file will be named ${DISTRO_FILE_PREFIX}save.2fs and will be created in a place that you nominate.")
$(gettext "If you have installed Puppy to hard drive, or installed such that personal storage is an entire partition, then you will not have a ${DISTRO_FILE_PREFIX}save.2fs file either.")"
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
PARTSIZE=`df -m | grep "$APATTERN" | tr -s " " | cut -f 2 -d " "`
PARTFREE=`df -m | grep "$APATTERN" | tr -s " " | cut -f 4 -d " "`

. /usr/lib/gtkdialog/svg_bar 200 "$(((($ACTUALSIZE-$SIZEFREE)*200/$ACTUALSIZE)))" "$ACTUALSIZE Mb / $SIZEFREE Mb $(gettext 'free')"  > /tmp/resizepfile_pfile.svg
. /usr/lib/gtkdialog/svg_bar 200 "$(((($PARTSIZE-$PARTFREE)*200/$PARTSIZE)))" "$PARTSIZE Mb / $PARTFREE Mb $(gettext 'free')"  > /tmp/resizepfile_partition.svg
 
x='
<window title="'$(gettext 'Resize Personal Storage File')'" icon-name="gtk-refresh"> 
<vbox space-expand="true" space-fill="true">
  '"`/usr/lib/gtkdialog/xml_info fixed puppy_increase.svg 60 "$(gettext "<b>Your personal file is ${NAMEPFILE},</b> and this contains user data, configuration files, email, newsgroup cache, history files and installed packages...")" "$(gettext "If you see that you are running low on space in $NAMEPFILE, you can make it bigger, but of course there must be enough space in $SAVEPART.")"`"'
  <vbox space-expand="true" space-fill="true">
    <frame>      
      <text height-request="5"><label>""</label></text>
      <vbox space-expand="true" space-fill="true">
        <vbox space-expand="false" space-fill="false">
          <hbox>
            <text xalign="0" use-markup="true"><label>"<b>'$(gettext 'Personal File')'</b>: '$NAMEPFILE'"</label></text>
            <text space-expand="true" space-fill="true"><label>""</label></text>
            <pixmap><input file>/tmp/resizepfile_pfile.svg</input></pixmap>
          </hbox>
          <hbox>
            <text xalign="0" use-markup="true"><label>"<b>'$(gettext 'Partition')'</b>: '$SAVEPART'"</label></text>
            <text space-expand="true" space-fill="true"><label>""</label></text>
            <pixmap><input file>/tmp/resizepfile_partition.svg</input></pixmap>
          </hbox>
        </vbox>
        <text height-request="5" space-expand="true" space-fill="true"><label>""</label></text>
        <vbox space-expand="false" space-fill="false">
          <hbox space-expand="true" space-fill="true">
            <text xalign="0" space-expand="true" space-fill="true"><label>'$(gettext "Increase size of $NAMEPFILE by amount (Mb). You cannot make it smaller.")'</label></text>
            <comboboxtext width-request="100" space-expand="false" space-fill="false">
              <variable>KILOBIG</variable>
              <item>32</item>
              <item>64</item>
              <item>128</item>
              <item>256</item>
              <item>512</item>
              <item>1024</item>
              <item>2048</item>
              <item>4096</item>
            </comboboxtext>
          </hbox>
        </vbox>
        <text height-request="10"><label>""</label></text>
      </vbox>
    </frame>
  </vbox>
  <hbox space-expand="false" space-fill="false">
    '"`/usr/lib/gtkdialog/xml_pixmap nb`"'
    <text xalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<b>'$(gettext 'Resizing requires a system reboot')'</b>"</label></text>
    <button space-expand="false" space-fill="false">
      <label>'$(gettext "Cancel")'</label>
      '"`/usr/lib/gtkdialog/xml_button-icon cancel`"'
      <action type="exit">EXIT_NOW</action>
    </button>
    <button space-expand="false" space-fill="false">
      <label>'$(gettext "Ok")'</label>
      '"`/usr/lib/gtkdialog/xml_button-icon ok`"'
      <action type="exit">save</action>
    </button>
  </hbox>
</vbox>
</window>'
export resize="$x"
. /usr/lib/gtkdialog/xml_info gtk > /dev/null #build bg_pixmap for gtk-theme
eval $(gtkdialog -p resize)
case ${EXIT} in
  save)KILOBIG=$(($KILOBIG * 1024))
  echo "$KILOBIG" > /initrd${PUP_HOME}/pupsaveresize.txt;;
   *)
    exit
   ;;
esac

echo -n "$KILOBIG" > /initrd${PUP_HOME}/pupsaveresize.txt


/usr/lib/gtkdialog/box_ok "$(gettext 'Resize personal storage file')" complete "$(gettext "Okay, you have chosen to <b>increase ${NAMEPFILE} by ${KILOBIG} Kbytes</b>, however as the file is currently in use, it will happen at reboot.")" " " "$(gettext 'Technical notes:')" "$(gettext "The required size increase has been written to file pupsaveresize.txt, in partition ${SAVEPART} (currently mounted on /mnt/home).")" "$(gettext 'File pupsaveresize.txt will be read at bootup and the resize performed then pupsaveresize.txt will be deleted.')" "$(gettext "WARNING: If you have multiple ${DISTRO_FILE_PREFIX}save files, be sure to select the same one when you reboot.")" " " "<b>$(gettext 'You can keep using Puppy. The change will only happen at reboot.')</b>"

###END###

#notes:
#  dd if=/dev/zero bs=1k count=$KILOBIG | tee -a $HOMELOCATION > /dev/null
