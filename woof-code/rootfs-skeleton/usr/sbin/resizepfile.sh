#!/bin/sh
#2007 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html)
#make the pup_save.2fs file bigger.
#131231 Unknown author
#230926 1.0.0 [arbirary version] ozboomer: Include images showing result of size change
#230928 radky: minor adjustments in script syntax and GUI presentation

export TEXTDOMAIN=resizepfile.sh
export TEXTDOMAINDIR=/usr/share/locale #230926 Reinstated (for completeness)
export OUTPUT_CHARSET=UTF-8

export SIZEFREE     # These need to be exported for gtkdialog function use  #230926
export ACTUALSIZE
export PARTSIZE
export PARTFREE

export pixbuf_dir="/usr/share/pixmaps/puppy"    # 'freememapplet'-style icons  #230926
export dire_pixbuf="container_0.svg"            # red
export critical_pixbuf="container_1.svg"        # orange
export ok_pixbuf="container_2.svg"              # yellow
export good_pixbuf="container_3.svg"            # (partial) green 
export excellent_pixbuf="container_4.svg"       # (full) green

########################################################################
#                                                                      #
# FUNCTIONS                                                            #
#                                                                      #
########################################################################

# Build disk usage images
svg_bar () {
   SVG_BAR_COLOR_USED='#006793' SVG_BAR_COLOR_TOTAL='#444444' SVG_BAR_COLOR_TEXT='#E5E5E5' SVG_BAR_HEIGHT=38

   echo '<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" height="'$SVG_BAR_HEIGHT'" width="'$1'">
  <defs>
	<linearGradient id="LGD_02">
	  <stop style="stop-color:'$SVG_BAR_COLOR_USED';stop-opacity:1" offset="0" />
	  <stop style="stop-color:'$SVG_BAR_COLOR_USED';stop-opacity:0" offset="1" />
	</linearGradient>
	<linearGradient id="LG_02"
	   x1="'$(($2-3))'" y1="10" x2="'$2'" y2="10"
	   xlink:href="#LGD_02"
	   gradientUnits="userSpaceOnUse" />
  </defs>
  <rect style="fill:'$SVG_BAR_COLOR_TOTAL';stroke:#111111;stroke-width:3" width="'$1'" height="'$SVG_BAR_HEIGHT'" x="0" y="0"/>
  <rect style="fill:url(#LG_02);" width="'$(($1-3))'" height="'$(($SVG_BAR_HEIGHT-3))'" x="1.5" y="1.5"/>
  <path style="fill:none;stroke:#ffffff;stroke-width:3" d="M 0,'$SVG_BAR_HEIGHT' '$1','$SVG_BAR_HEIGHT' M '$1',0 '$1','$SVG_BAR_HEIGHT'"/>
  <text
	 style="fill:'$SVG_BAR_COLOR_TEXT';font-family:sans-serif;font-size:'$(($SVG_BAR_HEIGHT/2))';text-anchor:middle"
	 x="'$(($1/2))'" y="'$(($SVG_BAR_HEIGHT*17/24))'">
	'$3'
  </text>
</svg>'
}
export -f svg_bar

# Create/Update disk usage images (and optionally usage icons)
create_images () { #230926
   local SIZE="$1"
   local FREE="$2"
   local DISK_IMG_FILE="$3"
   local ICON_FILE="$4"
   local IMG=""
   local PERCENT_FREE=0
   W=320

   svg_bar ${W} "$(((($SIZE-$FREE)*200/$SIZE)))" "${SIZE}M / ${FREE}M $(gettext 'free')" > "$DISK_IMG_FILE"

   if [[ "$ICON_FILE" != "" ]]; then
      if (( SIZE == 0 )); then
         PERCENT_FREE=0
      else
         PERCENT_FREE=$(( (FREE * 100) / SIZE ))
      fi

      if (( FREE < 20 )); then # Same limits as freememapplet_tray 2.8.6
         IMG="$pixbuf_dir/$dire_pixbuf"
         # not this time ... blink_mode=true
      elif (( FREE < 50 )); then
         IMG="$pixbuf_dir/$critical_pixbuf"
      elif (( PERCENT_FREE < 20 )); then
         IMG="$pixbuf_dir/$critical_pixbuf"
      elif (( PERCENT_FREE < 45 )); then
         IMG="$pixbuf_dir/$ok_pixbuf"
      elif (( PERCENT_FREE < 70 )); then
         IMG="$pixbuf_dir/$good_pixbuf"
      else
         IMG="$pixbuf_dir/$excellent_pixbuf"
      fi
      cp --force "$IMG" "$ICON_FILE"
   fi
}
export -f create_images     # used by gtkdialog

# Update 'new' disk images/icons for proposed usage
update_images () {  #230926
   UPD_ACTUALSIZE=$(($ACTUALSIZE + $KILOBIG)) # KILOBIG is the combobox value (Mb value)
   UPD_SIZEFREE=$(($SIZEFREE + $KILOBIG))

   UPD_PARTSIZE=$(($PARTSIZE + $KILOBIG))
   UPD_PARTFREE=$(($PARTFREE - $KILOBIG))

   create_images "$UPD_ACTUALSIZE" "$UPD_SIZEFREE" "/tmp/resizepfile_pf_upd.svg" "/tmp/resizepfile_pf_icon.svg" 
   create_images "$UPD_PARTSIZE"   "$UPD_PARTFREE" "/tmp/resizepfile_pn_upd.svg" "/tmp/resizepfile_pn_icon.svg" 
}
export -f update_images     # used by gtkdialog

# Remove temporary image files
cleanup () { #230926
   [[ -f "/tmp/resizepfile_pfile.svg" ]] && rm "/tmp/resizepfile_pfile.svg"
   [[ -f "/tmp/resizepfile_partition.svg" ]] && rm "/tmp/resizepfile_partition.svg"
   [[ -f "/tmp/resizepfile_pf_icon.svg" ]] && rm "/tmp/resizepfile_pf_icon.svg"
   [[ -f "/tmp/resizepfile_pn_icon.svg" ]] && rm "/tmp/resizepfile_pn_icon.svg"
   [[ -f "/tmp/resizepfile_pf_upd.svg" ]] && rm "/tmp/resizepfile_pf_upd.svg"
   [[ -f "/tmp/resizepfile_pn_upd.svg" ]] && rm "/tmp/resizepfile_pn_upd.svg"
}

########################################################################
#                                                                      #
# SAVEFILE PARAMETERS                                                  #
#                                                                      #
########################################################################

. gettext.sh            # gtk text formatting
. /etc/rc.d/PUPSTATE    # variables created at bootup by /initrd/usr/sbin/init...
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

#230926 Create initial disk images
# ...existing usage
create_images "$ACTUALSIZE" "$SIZEFREE" "/tmp/resizepfile_pfile.svg"
create_images "$PARTSIZE"   "$PARTFREE" "/tmp/resizepfile_partition.svg"

# ...proposed usage
create_images "$ACTUALSIZE" "$SIZEFREE" "/tmp/resizepfile_pf_upd.svg" "/tmp/resizepfile_pf_icon.svg"
create_images "$PARTSIZE"   "$PARTFREE" "/tmp/resizepfile_pn_upd.svg" "/tmp/resizepfile_pn_icon.svg"

#230926 Zero is now valid (to show current state)
for i in 0 32 64 128 256 512 1024 2048 4096 8192 12288 16384 24576 32768 65536
do
    [ $i -lt $PARTFREE ] && MBCOMBO="$MBCOMBO <item>${i}</item>"
done

########################################################################
#                                                                      #
# MAIN DIALOG                                                          #
#                                                                      #
########################################################################

x='
<window title="'$(gettext 'Resize Personal Storage File')'" icon-name="gtk-refresh" resizable="false"> 
<vbox space-expand="false" space-fill="false">
  '"$(/usr/lib/gtkdialog/xml_info fixed puppy_increase.svg 90 "$(eval_gettext "<b>Your personal file is \${NAMEPFILE},</b> and this contains user data, configuration files, email, newsgroup cache, history files and installed packages...")" "$(eval_gettext "If you see that you are running low on space in \$NAMEPFILE, you can make it bigger, but of course there must be enough space in \$SAVEPART.")")"'
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
        <text height-request="5" space-expand="false" space-fill="false"><label>""</label></text>
        <hseparator></hseparator>
        <text height-request="5" space-expand="false" space-fill="false"><label>""</label></text>
        <vbox space-expand="false" space-fill="false">
          <hbox space-expand="true" space-fill="true">
            <text xalign="0" space-expand="true" space-fill="true"><label>'$(eval_gettext "Increase size of \$NAMEPFILE by amount (Mb). You cannot make it smaller.")'</label></text>
            <comboboxtext wrap-width="3" width-request="110" space-expand="false" space-fill="false">
              <variable>KILOBIG</variable>
              '${MBCOMBO}'
              <action>update_images</action>
              <action>refresh:PF_ICON</action>
              <action>refresh:APIC</action>
              <action>refresh:PN_ICON</action>
              <action>refresh:BPIC</action>
            </comboboxtext>
          </hbox>
          <hbox>
            <text xalign="0" space-expand="true" use-markup="true" space-fill="true">
               <label>
                  "<b><span color='"'teal'"'>After Resizing:</span></b>"
               </label>
            </text>
          </hbox>
          <hbox>            
            <text xalign="0" use-markup="true"><label>"<b>'$(gettext 'Personal File')'</b>:"</label></text>
            <text space-expand="true" space-fill="true"><label>""</label></text>
            <pixmap space-expand="false" space-fill="false">
               <variable>PF_ICON</variable>
               <input file>/tmp/resizepfile_pf_icon.svg</input>
               <height>30</height>
            </pixmap>
            <pixmap>
               <variable>APIC</variable>
               <input file>/tmp/resizepfile_pf_upd.svg</input>
            </pixmap>
          </hbox>
          <hbox>
            <text xalign="0" use-markup="true"><label>"<b>'$(gettext 'Partition')'</b>:"</label></text>
            <text space-expand="true" space-fill="true"><label>""</label></text>
            <pixmap space-expand="false" space-fill="false">
               <variable>PN_ICON</variable>
               <input file>/tmp/resizepfile_pn_icon.svg</input>
               <height>30</height>
            </pixmap>
            <pixmap>
               <variable>BPIC</variable>
               <input file>/tmp/resizepfile_pn_upd.svg</input>
            </pixmap>
          </hbox>
        </vbox>
        <text height-request="10"><label>""</label></text>
      </vbox>
    </frame>
  </vbox>

  <hbox space-expand="false" space-fill="false">
    '"`/usr/lib/gtkdialog/xml_pixmap nb.svg 18`"'
    <text xalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<b><span color='"'red'"'>'$(gettext 'Resizing requires a system reboot')'</span></b>"</label></text>
    <button space-expand="false" space-fill="false">
      <label>'$(gettext "Cancel")'</label>
      '"`/usr/lib/gtkdialog/xml_button-icon cancel`"'
      <action type="exit">EXIT_NOW</action>
    </button>
    <button space-expand="false" space-fill="false">
      <variable>OKBUTTTON</variable>
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
    if [[ $KILOBIG -ne 0 ]]; then #230926
       KILOBIG=$(($KILOBIG * 1024))
       echo "KILOBIG=$KILOBIG" > /initrd${PUP_HOME}/pupsaveresizenew.txt
       echo "PUPSAVEFILEX=$SAVEFILE" >> /initrd${PUP_HOME}/pupsaveresizenew.txt #131231
       /usr/lib/gtkdialog/box_ok "$(gettext 'Resize personal storage file')" complete "$(eval_gettext "Okay, you have chosen to <b>increase the size of \${NAMEPFILE} by <span color='"'blue'"'>\${KILOBIG} Kbytes</span></b>, however as the file is currently in use, it will happen at reboot.")" " " "$(gettext 'Technical notes:')" "$(eval_gettext "The required size increase has been written to file pupsaveresizenew.txt, in partition \${SAVEPART} (currently mounted on /mnt/home).")" "$(gettext 'File pupsaveresizenew.txt will be read at bootup and the resize performed then pupsaveresizenew.txt will be deleted.')" "$(eval_gettext "WARNING: If you have multiple \${DISTRO_FILE_PREFIX}save files, be sure to select the same one when you reboot.")" " " "<b><span color='"'blue'"'>$(gettext "You can keep using Puppy. The change will only happen at reboot.")</span></b>" > /dev/null
    else
       if [[ -f /initrd${PUP_HOME}/pupsaveresizenew.txt ]]; then
          rm /initrd${PUP_HOME}/pupsaveresizenew.txt       
       fi
    fi
    ;;
esac

cleanup  #230926 remove temporary image files in /tmp

exit 0

### END ###
