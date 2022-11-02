#!/bin/sh
#2007 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html)
#make the pup_save.2fs file bigger.

export TEXTDOMAIN=resizepfile.sh
export OUTPUT_CHARSET=UTF-8

. gettext.sh
. /etc/rc.d/PUPSTATE #variables created at bootup by /initrd/usr/sbin/init...
. /etc/DISTRO_SPECS

if [ -f /initrd/tmp/no_resize2fs ] ; then #set by the initrd init script...
	/usr/lib/gtkdialog/box_ok "$(gettext 'Resize Personal Storage File')" error \
	"$(gettext 'The resize2fs binary is not present in initrd.gz... cannot continue')"
	exit 1
fi

case $PUPMODE in
	"12") PERSISTMNTPT="/initrd/pup_rw"  ;;
	"13") PERSISTMNTPT="/initrd/pup_ro1" ;;
	*) /usr/lib/gtkdialog/box_ok "$(gettext 'Resize personal storage file')" error "<b>$(gettext "Sorry, Puppy is not currently using a personal persistent storage file.")</b>" " " "$(eval_gettext "If this is the first time that you booted Puppy, say from a live-CD, you are currently running totally in RAM and you will be asked to create a personal storage file when you end the session (shutdown the PC or reboot).")
$(eval_gettext "If you have installed Puppy to hard drive, or installed such that personal storage is an entire partition, then you will not have a \${DISTRO_FILE_PREFIX}save.2fs file either.")"

esac

if [ -L "$PERSISTMNTPT" ] ; then
	PERSISTMNTPT="`readlink "$PERSISTMNTPT"`"
	[ -d "$PERSISTMNTPT" ] && PERSISTMNTPT="${PERSISTMNTPT%/upper}"
fi

SAVEFS="`echo -n "$PUPSAVE" | cut -f 2 -d ','`"
SAVEPART="`echo -n "$PUPSAVE" | cut -f 1 -d ','`"
SAVEFILE="`echo -n "$PUPSAVE" | cut -f 3 -d ','`"
NAMEPFILE="`basename $SAVEFILE`"

HOMELOCATION="/initrd${PUP_HOME}${SAVEFILE}"
if [ -d $HOMELOCATION ] ; then
	exec /usr/lib/gtkdialog/box_ok "$(gettext 'Resize personal storage file')" info "<b>$(gettext "Puppy is currently using a savefolder. There is no need to resize it")</b>" " "
fi

SIZEFREE=`df -m | grep "$PERSISTMNTPT" | tr -s " " | cut -f 4 -d " "` #free space in ${DISTRO_FILE_PREFIX}save.3fs
ACTUALSIZK=`stat -c %s $HOMELOCATION` #total size of ${DISTRO_FILE_PREFIX}save.3fs
ACTUALSIZE=`expr $ACTUALSIZK \/ 1024 \/ 1024`
APATTERN="/dev/${SAVEPART} "
PARTSIZE=`df -m | grep "$APATTERN" | tr -s " " | cut -f 2 -d " "`
PARTFREE=`df -m | grep "$APATTERN" | tr -s " " | cut -f 4 -d " "`

. /usr/lib/gtkdialog/svg_bar 200 "$(((($ACTUALSIZE-$SIZEFREE)*200/$ACTUALSIZE)))" "$ACTUALSIZE Mb / $SIZEFREE Mb $(gettext 'free')"  > /tmp/resizepfile_pfile.svg
. /usr/lib/gtkdialog/svg_bar 200 "$(((($PARTSIZE-$PARTFREE)*200/$PARTSIZE)))" "$PARTSIZE Mb / $PARTFREE Mb $(gettext 'free')"  > /tmp/resizepfile_partition.svg

for i in 32 64 128 256 512 1024 2048 4096 8192 12288 16384 24576 32768 65536
do
	[ $i -lt $PARTFREE ] && MBCOMBO="$MBCOMBO <item>${i}</item>"
done

x='
<window title="'$(gettext 'Resize Personal Storage File')'" icon-name="gtk-refresh" resizable="false"> 
<vbox space-expand="true" space-fill="true">
  '"$(/usr/lib/gtkdialog/xml_info fixed puppy_increase.svg 60 "$(eval_gettext "<b>Your personal file is \${NAMEPFILE},</b> and this contains user data, configuration files, email, newsgroup cache, history files and installed packages...")" "$(eval_gettext "If you see that you are running low on space in \$NAMEPFILE, you can make it bigger, but of course there must be enough space in \$SAVEPART.")")"'
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
            <text xalign="0" space-expand="true" space-fill="true"><label>'$(eval_gettext "Increase size of \$NAMEPFILE by amount (Mb). You cannot make it smaller.")'</label></text>
            <comboboxtext width-request="100" space-expand="false" space-fill="false">
              <variable>KILOBIG</variable>
              '${MBCOMBO}'
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
eval $(gtkdialog -p resize --styles=/tmp/gtkrc_xml_info.css)
case ${EXIT} in save)
	KILOBIG=$(($KILOBIG * 1024))
	echo "KILOBIG=$KILOBIG" > /initrd${PUP_HOME}/pupsaveresizenew.txt
	echo "PUPSAVEFILEX=$SAVEFILE" >> /initrd${PUP_HOME}/pupsaveresizenew.txt #131231
	/usr/lib/gtkdialog/box_ok "$(gettext 'Resize personal storage file')" complete "$(eval_gettext "Okay, you have chosen to <b>increase \${NAMEPFILE} by \${KILOBIG} Kbytes</b>, however as the file is currently in use, it will happen at reboot.")" " " "$(gettext 'Technical notes:')" "$(eval_gettext "The required size increase has been written to file pupsaveresizenew.txt, in partition \${SAVEPART} (currently mounted on /mnt/home).")" "$(gettext 'File pupsaveresizenew.txt will be read at bootup and the resize performed then pupsaveresizenew.txt will be deleted.')" "$(eval_gettext "WARNING: If you have multiple \${DISTRO_FILE_PREFIX}save files, be sure to select the same one when you reboot.")" " " "<b>$(gettext 'You can keep using Puppy. The change will only happen at reboot.')</b>"
	;;
esac

### END ###
