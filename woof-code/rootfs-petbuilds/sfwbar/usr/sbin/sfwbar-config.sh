#!/bin/bash

# sfwbar config
# GPLv2 (/usr/share/doc/legal)

CONF=$HOME/.config/sfwbar/extrabar.conf
rm -f /tmp/sfwlaunch*.lst

#----------------------------- functions  -----------------------------#

parse_line() {
	N="$1"
	grep "${N}$" /tmp/sfwlaunch.lst >> /tmp/sfwlaunchCONF.lst
	grep "${N}" /tmp/sfwlaunchP.lst >> /tmp/sfwlaunchCONF.lst
}

move() { # https://wikka.puppylinux.com/gtkdialogDocTips9.7 - thanks ziggy!
	PRESS_EVENT=$(cat /tmp/sfwlaunchPRESS_EVENT)
	echo "p $PRESS_EVENT t $TREE" > /tmp/tree
	[[ $PRESS_EVENT && $TREE  ]] || return 
	[[ $PRESS_EVENT == $TREE  ]] && return 
	sed -i "/$PRESS_EVENT/d; /$TREE/ i\\$PRESS_EVENT" /tmp/sfwlaunchSEL.lst
}

restart_sfwbar() {
	SFWBAR_PID=$(pidof -s sfwbar)
	if [ -n "$SFWBAR_PID" ]; then
		kill -HUP $SFWBAR_PID
	else
		sfwbar &
	fi
}

disable_launch() {
	sed -i '2s/true/false/' $HOME/.config/sfwbar/launcher.widget
	gtkdialog-splash -bg pink -placement top -timeout 2 -text "$(gettext "Disabling launcher.")" &
}

enable_launch() {
	sed -i '2s/false/true/' $HOME/.config/sfwbar/launcher.widget
	gtkdialog-splash -bg green -placement top -timeout 2 -text "$(gettext "Enabling launcher.")" &
}

orient_bar() {
	#$1 = line no, $2 old pos, $3 = new pos
	sed -i "${1}s/$2/$3/" $HOME/.config/sfwbar/sfwbar.config
}

update_radii() {
	# $1 = old radius, $2 = new radius
	sed -i "s/border-radius: ${1}px;/border-radius: ${2}px;/g" $HOME/.config/sfwbar/sfwbar.config
	sed -i "s/border-radius.*$/border-radius: ${2}px;/g" $HOME/.config/sfwbar/launcher.css
}

update_size() {
	# set icon size and exclusive zone
	case $1 in
		24)PX=24;MB=18;FntS=10;;
		28)PX=28;MB=22;FntS=10;;
		30)PX=30;MB=24;FntS=11;;
		36)PX=36;MB=30;FntS=12;;
		42)PX=42;MB=36;FntS=13;;
	esac
	IMGLN=$(grep -n 'button#taskbar_normal image' $HOME/.config/sfwbar/sfwbar.config)
	IMGNO=${IMGLN%\:button*}
	TWLN=$(($IMGNO + 2))
	THLN=$(($IMGNO + 3))
	sed -i \
		   -e "s/font: \([0-9][0-9]\)pt Sans/font: ${FntS}pt Sans/" \
		   -e "${TWLN}s/\([0-9][0-9]\)px/$((${PX}*2/3))px/" \
		   -e "${THLN}s/\([0-9][0-9]\)px/$((${PX}*2/3))px/" \
		$HOME/.config/sfwbar/sfwbar.config
	for widget in $(ls $HOME/.config/sfwbar/|grep 'widget$'); do
		SZ=$(grep -m1 -o 'min.*width' $HOME/.config/sfwbar/$widget|grep -o '[0-9][0-9].*px')
		case $widget in
			clock*)sed -i "s/\([0-9][0-9]\)pt/${FntS}pt/g" $HOME/.config/sfwbar/$widget ;;
			cpu*|load*|memory*|swap*|disk*)
				sed -i "s/min-height: \([0-9][0-9]\)px\;/min-height: $((${PX} - 2))px\;/" $HOME/.config/sfwbar/$widget ;;
			'launcher.widget');;
			'buttonmenu.widget')
				sed -i -e "s/min-height: \([0-9][0-9]\)px/min-height: ${MB}px/"\
					-e "s/min-width: \([0-9][0-9]\)px/min-width: $((${MB} * 4 / 3))px/"\
					$HOME/.config/sfwbar/buttonmenu.widget
					;;
			*)sed -i "s/\([0-9][0-9]\)px/${PX}px/g" $HOME/.config/sfwbar/$widget ;;
		esac
	done

}

export -f parse_line move restart_sfwbar disable_launch enable_launch orient_bar update_radii update_size

#-------------------------------- main --------------------------------#
FULL=true # full gui

[ "$1" = '-r' ] && restart_sfwbar && exit
[ "$1" = '-f' ] && disable_launch && exit
[ "$1" = '-e' ] && enable_launch && exit
[ "$1" = '-fr' ] && disable_launch && restart_sfwbar && exit
[ "$1" = '-er' ] && enable_launch && restart_sfwbar && exit
[ "$1" = '-o' ] && orient_bar $2 $3 $4 && exit
[ "$1" = '-c' ] && FULL=false # cut down gui
[ "$1" = '-x' ] && update_radii $2 $3 && exit

read -d ':' TGT_LN z <<<$(grep -n '^window#panel' $HOME/.config/sfwbar/sfwbar.config)
read -d ';' x y TGT_STR <<<$(sed -n ${TGT_LN}p $HOME/.config/sfwbar/sfwbar.config)
DEF_BARPOS=${TGT_STR##*\ }
case $DEF_BARPOS in
	top)X_BARPOS=bottom;;
	bottom)X_BARPOS=top;;
esac

read -d ';' w x DEF_POS <<<$(grep -n 'window#launcher' $HOME/.config/sfwbar/sfwbar.config)
DEF_POS=${DEF_POS##*\ }
nn=0
for c in $DEF_POS top bottom left right ; do
	[ "$c" = "$DEF_POS" ] && [ $nn -gt 0 ] && continue
	CITEMS="${CITEMS}<item>$c</item>"
	nn=$((nn + 1))
done

while read mon; do
	MONS="${MONS}
		<item>${mon%\ *}</item>"
done <<< $(wlopm)

MNR=$(printf "$MONS" | wc -l)
if [ $MNR -gt 1 ]; then
	read xx yy DEF_MON0 <<<$(grep -m1 'SetMonitor "panel"' $HOME/.config/sfwbar/sfwbar.config|sed 's/\"//g') 
	MONS0="		<comboboxtext>
            <item>$DEF_MON0</item>
            $(printf "%s\n" "$MONS"|grep -v $DEF_MON0)
          <variable>MON0</variable>
        </comboboxtext>"

	read xx yy DEF_MON1 <<<$(grep -m1 'SetMonitor "launcher"' $HOME/.config/sfwbar/sfwbar.config|sed 's/\"//g') 
	MONS1="		<comboboxtext>
            <item>$DEF_MON1</item>
            $(printf "%s\n" "$MONS"|grep -v $DEF_MON1)
          <variable>MON1</variable>
        </comboboxtext>"
else
	MONS0='' MONS1=''
fi

DEFRAD_NR=$(grep -n 'button {' ~/.config/sfwbar/sfwbar.config)
read -d ';' j DEFRAD <<<$(sed -n $((${DEFRAD_NR%%\:*} + 3))p $HOME/.config/sfwbar/sfwbar.config)
DEFSIZE=$(grep -o 'min-width.*;' $HOME/.config/sfwbar/logout.widget|grep -o '[0-9][0-9]px')
DEFRAD=${DEFRAD/px/}
DEFSIZE=${DEFSIZE/px/}

if [ "$FULL" = 'true' ]; then
	gtkdialog-splash -bg green -close never -placement top -text "$(gettext "Please wait a moment.")" &
	gpid=$!

	# puppy apps
	for p in wordprocessor spreadsheet email calendar ; do
		grep -qE 'abiword|office|gnumeric|claws|sylpheed|thunderbird|osmo' /usr/local/bin/default${p} &&\
		case $p in
			word*)W='document|defaultwordprocessor|Word Processor' ;;
			spread*)S='spreadsheet|defaultspreadsheet|Spread Sheet';;
			email)E='mail|defaultemail|Email'                     ;;
			calendar)C='calendar|defaultcalendar|Calendar'         ;;
		esac
	done
	for z in \
	'directory-home|defaultfilemanager|File Manager' \
	'browser|defaultbrowser|Browser' \
	'terminal|defaultterminal|Terminal' \
	"$W" \
	"$S" \
	"$E" \
	"$C" \
	'edit|defaulttexteditor|Text Editor' \
	'mplayer|defaultmediaplayer|Media Player' \
	'paint|defaultpaint|Paint'
	do
		[ -n "$z" ] && echo "$z" >> /tmp/sfwlaunchP.lst
		if [ -n "$z" ]; then
			read l m n <<<$(echo $z | tr '|' ' ')
			echo "$m ," >> /tmp/sfwlaunchPUP.lst
		fi
	done
	
	# main apps
	for i in /usr/share/applications/*; do
		grep -q "^NoDisplay=true" $i && continue
		grep -q "^Icon" $i || continue
		NAME="$(grep -m1 "^Name=" $i)"
		EXEC="$(grep -m1 "^Exec=" $i)"
		ICON="$(grep -m1 "^Icon=" $i)"
		# ignore full path, use icon theme only apps (mostly)
		echo ${ICON#*=} | grep -q '^/' && continue
		echo "${ICON#*=}|${EXEC#*=}|${NAME#*=}" >> /tmp/sfwlaunch.lst
		echo "${NAME#*=} ," >> /tmp/sfwlaunchGUI.lst
	done

	kill -9 $gpid

	EXTRAS='<hseparator></hseparator>
    <hbox space-expand="true" space-fill="true">
    <hbox space-expand="true" space-fill="true">
      <frame '$(gettext "Choose Puppy apps")'>
        <text><label>'$(gettext "Choose up to 10 apps to include in your launcher")'</label></text>
        <tree headers-clickable="false" selection-mode="3" tooltip-text="'$(gettext "Hold Ctrl key to press multiple selections")'">
         <variable>SELECTIONSPUP</variable>
         <label>'$(gettext "Available Puppy apps")'</label>
         <input>cat /tmp/sfwlaunchPUP.lst</input>
        </tree>
        <variable>CHOOSEPUP</variable>
      </frame>
    </hbox>
    <hbox space-expand="true" space-fill="true">
      <frame '$(gettext "Choose apps")'>
        <text><label>'$(gettext "Choose up to 10 apps to include in your launcher")'</label></text>
        <tree headers-clickable="false" selection-mode="3" tooltip-text="'$(gettext "Hold Ctrl key to press multiple selections")'">
         <variable>SELECTIONS</variable>
         <label>'$(gettext "Available apps")'</label>
         <input>cat /tmp/sfwlaunchGUI.lst</input>
        </tree>
        <variable>CHOOSE</variable>
        <sensitive>false</sensitive>
      </frame>
    </hbox>
    </hbox>'
	STOCKP='<text xalign="0"><label>'$(gettext "Check box to use basic stock Puppy apps or uncheck for all other apps")'</label></text>
        <checkbox>
          <label>'$(gettext "Stock")' Puppy</label>
          <input>echo true</input>
          <variable>CHECK</variable>
          <action>if false disable:CHOOSEPUP</action>
          <action>if true enable:CHOOSEPUP</action>
          <action>if false enable:CHOOSE</action>
          <action>if true disable:CHOOSE</action>
        </checkbox>
        <hseparator></hseparator>'
        IN='false'
	
else
	EXTRAS=''
	STOCKP=''
	IN='true'
fi
if grep -qm1 'false' $HOME/.config/sfwbar/launcher.widget ; then
	STATE=true
else
	STATE=false
fi
CSIZE=$(grep 'SIZE' $CONF|grep -o '[0-9][0-9]')

export GUI='<window title="SFW Bar and Launcher Configuration" icon-name="sfwbar">
  <vbox space-expand="true" space-fill="true">
  '"`/usr/lib/gtkdialog/xml_info fixed "desktop_tray_config.svg" 60 "$(gettext 'Here you can change the properties of the task bar and launcher. To keep your current launcher apps check Keep Current Launcher.')"`"' 
    <hbox space-expand="true" space-fill="true">
    <hbox space-expand="true" space-fill="false">
      <frame '$(gettext "Position")'>
        <text><label>'$(gettext "Set the screen position of your task bar")'</label></text>
        <hbox space-expand="true" space-fill="false">
	         <comboboxtext>
	          <item>'$DEF_BARPOS'</item>
	          <item>'$X_BARPOS'</item>
	          <variable>BARPOS</variable>
	        </comboboxtext>
	        '$MONS0'
        </hbox>
        <hseparator></hseparator>
        <hbox space-expand="true" space-fill="false">
        <text xalign="0"><label>'$(gettext "Task bar size")'</label></text>
	        <comboboxtext tooltip-text="'$(gettext "This adjusts icon size")'">
	          <default>'$DEFSIZE'</default>
	          <item>24</item>
	          <item>28</item>
	          <item>30</item>
	          <item>36</item>
	          <item>42</item>
	          <variable>NEWSIZE</variable>
	        </comboboxtext>
	    </hbox>
        <hseparator></hseparator>
	       <text><label>'$(gettext "Set the screen position and size of your launcher")'</label></text>
        <hbox space-expand="true" space-fill="false">
	        <comboboxtext>
	          '$CITEMS'
	          <variable>POS</variable>
	        </comboboxtext>
	        <comboboxtext>
	          <item>'$CSIZE'</item>
	          <item>24</item>
	          <item>32</item>
	          <item>36</item>
	          <item>42</item>
	          <item>48</item>
	          <item>56</item>
	          <item>64</item>
	          <variable>SIZE</variable>
	        </comboboxtext>
	        '$MONS1'
        </hbox>
        <variable>ITEMS</variable>
      </frame>
    </hbox>
    <hbox space-expand="true" space-fill="false">
      <frame '$(gettext "Options")'>
        '$STOCKP'
        <text xalign="0"><label>'$(gettext "Check/uncheck this box to disable/enable the launcher")'</label></text>
        <checkbox>
          <label>'$(gettext "Disable Launcher")'</label>
          <input>echo '$STATE'</input>
          <variable>DISABLE</variable>
          <action>if true disable:CHOOSEPUP</action>
          <action>if true disable:CHOOSE</action>
          <action>if true disable:STOCK</action>
          <action>if true disable:ITEMS</action>
        </checkbox>
        <hseparator></hseparator>
        <text xalign="0"><label>'$(gettext "Check this box to keep your current launcher")'</label></text>
        <checkbox>
          <label>'$(gettext "Keep Current Launcher")'</label>
          <input>echo '$IN'</input>
          <variable>KEEP</variable>
          <action>if true disable:CHOOSEPUP</action>
          <action>if true disable:CHOOSE</action>
          <action>if false enable:CHOOSEPUP</action>
          <action>if false enable:CHOOSE</action>
        </checkbox>
        <hseparator></hseparator>
        <hbox space-expand="true" space-fill="false">
        <text xalign="0"><label>'$(gettext "Border radius")'</label></text>
	        <comboboxtext>
	          <default>'$DEFRAD'</default>
	          <item>0</item>
	          <item>1</item>
	          <item>2</item>
	          <item>3</item>
	          <item>4</item>
	          <item>5</item>
	          <item>6</item>
	          <item>7</item>
	          <item>8</item>
	          <item>default</item>
	          <variable>RAD</variable>
	        </comboboxtext>
	    </hbox>
        <variable>STOCK</variable>
     </frame>
    </hbox>
    </hbox>
    '$EXTRAS'
    <hbox space-expand="false" space-fill="false">
      <button ok></button>
    </hbox>
  </vbox>
</window>'

. /usr/lib/gtkdialog/xml_info gtk #build bg_pixmap for gtk-theme
eval $(gtkdialog -p GUI --styles=/tmp/gtkrc_xml_info.css)
[ "$EXIT" = 'abort' ] && exit

if [ "$DEFRAD" != "$RAD" ]; then
	if [ $RAD = 'default' ]; then
		RAD=$(grep -o '<cornerRadius>.*[0-9]' ~/.config/labwc/rc.xml | tail -c2)
	fi
	update_radii $DEFRAD $RAD
fi
if [ "$DEFSIZE" != "$NEWSIZE" ]; then
	update_size $NEWSIZE
fi
# bar
[ "$POS" = "$BARPOS" ] && \
	gtkdialog-splash -bg pink -close box -text "$(gettext "Error: Bar and launcher postion must be different.")" && exit

if echo $TGT_STR | grep -qv "$BARPOS"; then
	orient_bar ${TGT_LN} $DEF_BARPOS $BARPOS #change orientation
fi
if ! grep -q "$BAR_MON" $HOME/.config/sfwbar/sfwbar.config ; then
	sed -i -e "s/#SetMonitor \"panel\".*$/SetMonitor \"panel\", \"$MON0\"/" -e "s/SetMonitor \"panel\".*$/SetMonitor \"panel\", \"$MON0\"/" $HOME/.config/sfwbar/sfwbar.config
fi

if [ "$DISABLE" = 'true' ]; then
	exec $0 -fr
elif [ "$DISABLE" = 'false' ]; then
	if [ "$KEEP" = 'false' ];then
		# launcher
		echo "POS=$POS" > /tmp/sfwlaunchCONF.lst
		echo "SIZE=$SIZE" >> /tmp/sfwlaunchCONF.lst
		[ -n "$MON1" ] && echo "MON1=$MON1" >> /tmp/sfwlaunchCONF.lst
		rm -f /tmp/sfwlaunchSEL.lst
		
		if [ -z "$SELECTIONS" -a "$CHECK" = 'false' ]; then
			gtkdialog-splash -bg pink -close box -text "$(gettext "Error: No apps chosen. Check 'Keep current launcher' to restore the previous configuration.")" && exec $0
		elif [ -z "$SELECTIONSPUP" -a "$CHECK" = 'true' ]; then
			gtkdialog-splash -bg pink -close box -text "$(gettext "Error: No Puppy apps chosen. Check 'Keep current launcher' to restore the previous configuration.")" exec $0
		fi
		
		# count the entries
		NR=0
		if [ "$CHECK" = 'true' ]; then
			# count the entries
			echo $SELECTIONSPUP | tr ',' '\n' | while read LINE ; do
				NR=$(($NR + 1))
				echo $NR > /tmp/NR
				echo "$LINE" >> /tmp/sfwlaunchSEL.lst
			done
		else
			echo $SELECTIONS | tr ',' '\n' | while read LINE ; do
				NR=$(($NR + 1))
				echo $NR > /tmp/NR
				echo "$LINE" >> /tmp/sfwlaunchSEL.lst
			done
		fi
		NR=$((`cat /tmp/NR` - 1))
		([ $NR -gt 10 ] || [ $NR -lt 2 ]) && gtkdialog-splash -bg pink -close box -text "$(gettext "Error: $NR entries. Please choose 2 or more or 10 or less.")" && exec $0
		
		# confirm and re-order gui
		export CONFIRM='<window title="'$(gettext 'Confirm?')'" icon-name="sfwconfig">
		  <vbox>
		    <frame '$(gettext "Position")'>
		      <text><label>'$POS'</label></text>
		    </frame>
		    <frame '$(gettext "Apps")'>
			  <text><label>'$(gettext "You can re-order your apps here.")'</label></text>
			  <tree headers-clickable="false" rules_hint="true" hover-selection="true" tooltip-text="'$(gettext "Drag and drop items to move them in list")'">
		        <label>'$(gettext "Re-order the launcher Apps")'</label>
		        <input>cat /tmp/sfwlaunchSEL.lst</input>
		        <variable>TREE</variable>
		        <height>300</height><width>200</width>
		        <action signal="button-press-event">echo $TREE > /tmp/sfwlaunchPRESS_EVENT</action>
		        <action signal="button-release-event">move</action>
		        <action signal="button-release-event">refresh:TREE</action>
		      </tree>
		    </frame>
			<hbox><button cancel></button><button ok></button></hbox>
		  </vbox>
		</window>'
		eval $(gtkdialog -p CONFIRM)
		
		case $EXIT in
			OK);;
			*)exit;;
		esac
		
		# write config
		while read PROG ; do
			[ -n "$PROG" ] && parse_line "$PROG"
		done < /tmp/sfwlaunchSEL.lst
		cat /tmp/sfwlaunchCONF.lst > $CONF
		sfwlauncher
	else
		sed -i "s/POS=.*$/POS=$POS/" $CONF
		sed -i "s/MON1=.*$/MON1=$MON1/" $CONF
		sed -i "s/SIZE=.*$/SIZE=$SIZE/" $CONF
		sed -i "s/SetMonitor \"panel\".*$/SetMonitor \"panel\", \"$MON0\"/" $HOME/.config/sfwbar/sfwbar.config
		if echo $TGT_STR | grep -qv "$BARPOS"; then
			orient_bar ${TGT_LN} $DEF_BARPOS $BARPOS #change orientation
		fi 
		sfwlauncher
	fi	
	
	exec $0 -er
fi
