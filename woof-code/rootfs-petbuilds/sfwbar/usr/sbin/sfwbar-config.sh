#!/bin/bash

# sfwbar config by 01micko
# GPLv2 (/usr/share/doc/legal)
# radky: update 1 Aug 2025
# 251020 peebee: add Edit taskbar config 
# 251021 wizard: add toggle visible/autohide

CONF=$HOME/.config/sfwbar/extrabar.conf
rm -f /tmp/sfwlaunch*.lst /tmp/launcher_selected 2>/dev/null

[ ! -f /usr/share/icons/hicolor/48x48/apps/desktop_tray_config.svg ] && \
ln -sf /usr/share/pixmaps/puppy/desktop_tray_config.svg /usr/share/icons/hicolor/48x48/apps && gtk-update-icon-cache -f -i /usr/share/icons/hicolor 2>/dev/null

#----------------------------- functions  -----------------------------#

toggle_visible() {
#check if bar is autohide
bhide=$(grep "SetBarSensor \"launcher\", \"500\"" /root/.config/sfwbar/sfwbar.config)
#toggle launchbar autohide or visible
if [ ! -z "$bhide" ]; then
   sed -i 's/SetBarSensor \"launcher\", \"500\"/SetBarSensor \"launcher\", \"0\"/' /root/.config/sfwbar/sfwbar.config
 else
   sed -i 's/SetBarSensor \"launcher\", \"0\"/SetBarSensor \"launcher\", \"500\"/' /root/.config/sfwbar/sfwbar.config  
fi
} 
export -f toggle_visible

current_launchbar_apps() {
    CLAPPS=`cat /tmp/sfwlaunchE.lst | cut -d'|' -f2- | cut -d'|' -f2`
    [ -z "$CLAPPS" ] && CLAPPS="$(gettext "No current launchers !")"
    echo "$CLAPPS" | Xdialog --fixed-font --title "$(gettext "Current Launchers")" --no-cancel --textbox "-" 22 55 2>/dev/null &
}

default_launchbar() {
    if [ "$DEFAULT_LAUNCHBAR" = "true" ]; then
        gtkdialog-splash -bg darkgoldenrod -placement top -timeout 4 -text "$(gettext "Restoring default launchbar !")" &
        echo -n 'Default file manager ,
Pmount ,
Package manager (Synaptic) ,
Puppy Setup ,
Default terminal ,
Default process manager ,
Default text editor ,
Default wordprocessor ,
Default spreadsheet ,
Default paint ,
Default browser ,
Default E-mail ,
Default connect app ,
Default calendar ,
Default mediaplayer ,
Log out ,
' > /tmp/sfwlaunchEXTRA.lst
    else
        gtkdialog-splash -bg darkgoldenrod -placement top -timeout 4 -text "$(gettext "Restoring last saved launchbar !")" &
        CLA=$(cat $HOME/.config/sfwbar/extrabar.conf | grep -v '=')
        if [ -n "$CLA" ]; then
            rm -f /tmp/sfwlaunchEXTRA.lst 2>/dev/null
            echo "$CLA" | cut -d'|' -f2- | cut -d'|' -f2 | while read LINE
            do
                [ -n "$LINE" ] && echo "$LINE ," >> /tmp/sfwlaunchEXTRA.lst
            done
        fi
    fi
}

parse_line() {
    N="$1"
    grep "${N}$" $HOME/.config/sfwbar/sfwlaunch.lst >> /tmp/sfwlaunchCONF.lst
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
}

disable_launch_notification() {
    gtkdialog-splash -bg darkgoldenrod -placement top -timeout 2 -text "$(gettext "Disabling launchbar")" &
}

enable_launch() {
    sed -i '2s/false/true/' $HOME/.config/sfwbar/launcher.widget
}

enable_launch_notification() {
    gtkdialog-splash -bg darkgoldenrod -placement top -timeout 2 -text "$(gettext "Enabling launchbar")" &
}

orient_bar() {
    #$1 = line no, $2 old pos, $3 = new pos
    sed -i "${1}s/$2/$3/" $HOME/.config/sfwbar/sfwbar.config
}

update_radii() {
    # $1 = old radius, $2 = new radius
    sed -i "s/border-radius.*$/border-radius: ${2}px;/g" $HOME/.config/sfwbar/sfwbar.config
    sed -i "s/border-radius.*$/border-radius: ${2}px;/g" $HOME/.config/sfwbar/launcher.css
}

update_menuitemsize() {
    # $1 = SFWbar new menu itemsize
    FontName=$(grep '{ font:' $HOME/.config/sfwbar/sfwbar.config | awk '{print $5}' | sed 's/;//')
    [ -z "$FontName" ] && FontName=Sans
    sed -i "s/{ font: .*$/{ font: ${1}pt ${FontName}; }/" $HOME/.config/sfwbar/sfwbar.config
    # sync Labwc menu itemsize with SFWbar new menu itemsize
    sed -i "/<font place=/,/font/ s/<size>.*<\/size>/<size>$1<\/size>/" $HOME/.config/labwc/rc.xml
    if [ "$GLOBAL" = "true" ]; then # apply new font size globally
        gsettings set org.gnome.desktop.interface font-name "$FontName $1"
        ptheme_gtk
    else # apply default font size globally (10pt)
        gsettings set org.gnome.desktop.interface font-name "$FontName 10"
        ptheme_gtk
    fi
    labwc -r
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
            bluez*)sed -i "s/min-height: .*px; min-width: .*px; padding:/min-height: ${PX}px; min-width: ${PX}px; padding:/" $HOME/.config/sfwbar/$widget ;;
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

launcher_add() {
    LAUNCHER=$(cat /tmp/launcher_selected 2>/dev/null)
    [ ! "$LAUNCHER" ] && exit 1
    if [ "`grep -aF -- "$LAUNCHER" /tmp/sfwlaunchEXTRA.lst 2>/dev/null`" ]; then
        gtkdialog-splash -bg darkgoldenrod -placement center -timeout 4 -text "$(gettext "$LAUNCHER already selected !")" &
    else
        sed -i "1i${LAUNCHER}" /tmp/sfwlaunchEXTRA.lst
    fi
}

launcher_remove() {
    LAUNCHER=$(cat /tmp/launcher_selected 2>/dev/null)
    [ ! "$LAUNCHER" ] && exit 1
    grep -aFv -- "$LAUNCHER" /tmp/sfwlaunchEXTRA.lst 2>/dev/null > /tmp/launcher_new
    mv -f /tmp/launcher_new /tmp/sfwlaunchEXTRA.lst
}

launcher_moveup() {
    LAUNCHER=$(cat /tmp/launcher_selected 2>/dev/null)
    LAUNCHER=$(grep -aF -- "$LAUNCHER" /tmp/sfwlaunchEXTRA.lst 2>/dev/null)
    LINE_BEFORE=$(grep -aF -B1 -- "$LAUNCHER" /tmp/sfwlaunchEXTRA.lst 2>/dev/null | grep -aFv -- "$LAUNCHER")
    if [ "$LINE_BEFORE" ]; then
     cat /tmp/sfwlaunchEXTRA.lst > /tmp/tmp
     grep -aF -B1000 -- "$LAUNCHER" /tmp/sfwlaunchEXTRA.lst 2>/dev/null | grep -aFv -- "$LAUNCHER" | grep -aFv -- "$LINE_BEFORE" > /tmp/tmp1
     grep -aF -A1000 -- "$LAUNCHER" /tmp/sfwlaunchEXTRA.lst 2>/dev/null | grep -aFv -- "$LAUNCHER" > /tmp/tmp2
     echo "$LAUNCHER" >> /tmp/tmp1
     echo "$LINE_BEFORE" >> /tmp/tmp1
     cat /tmp/tmp2 >> /tmp/tmp1
     mv -f /tmp/tmp1 /tmp/sfwlaunchEXTRA.lst
    fi
}

launcher_movedown() {
    LAUNCHER=$(cat /tmp/launcher_selected 2>/dev/null)
    LAUNCHER=$(grep -aF -- "$LAUNCHER" /tmp/sfwlaunchEXTRA.lst 2>/dev/null)
    LINE_AFTER=$(grep -aF -A1 -- "$LAUNCHER" /tmp/sfwlaunchEXTRA.lst 2>/dev/null | grep -aFv -- "$LAUNCHER")
    if [ "$LINE_AFTER" ]; then
     cat /tmp/sfwlaunchEXTRA.lst > /tmp/tmp
     grep -aF -B1000 -- "$LAUNCHER" /tmp/sfwlaunchEXTRA.lst 2>/dev/null | grep -aFv -- "$LAUNCHER" > /tmp/tmp1
     grep -aF -A1000 -- "$LAUNCHER" /tmp/sfwlaunchEXTRA.lst 2>/dev/null | grep -aFv -- "$LAUNCHER" | grep -aFv -- "$LINE_AFTER" > /tmp/tmp2
     echo "$LINE_AFTER" >> /tmp/tmp1
     echo "$LAUNCHER" >> /tmp/tmp1
     cat /tmp/tmp2 >> /tmp/tmp1
     mv -f /tmp/tmp1 /tmp/sfwlaunchEXTRA.lst
    fi
}

launchbar_position_override() {
    gtkdialog-splash -bg darkgoldenrod -placement center -timeout 5 -text "$(gettext "Launchbar position changed to $POS !")" &
}

export -f current_launchbar_apps default_launchbar parse_line restart_sfwbar disable_launch disable_launch_notification enable_launch enable_launch_notification orient_bar update_radii update_size update_menuitemsize launcher_add launcher_remove launcher_moveup launcher_movedown launchbar_position_override

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

if grep -qm1 'false' $HOME/.config/sfwbar/launcher.widget ; then
    STATE=true SENSITIVE=false
else
    STATE=false SENSITIVE=true
fi
export -f STATE SENSITIVE

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
    MONS0="        <comboboxtext width-request=\"185\">
            <item>$DEF_MON0</item>
            "$(printf "%s\n" "$MONS")"
          <variable>MON0</variable>
        </comboboxtext>"

read xx yy DEF_MON1 <<<$(grep -m1 'SetMonitor "launcher"' $HOME/.config/sfwbar/sfwbar.config|sed 's/\"//g') 
MONS1="        <comboboxtext sensitive="'"$SENSITIVE"'" width-request=\"185\">
        <item>$DEF_MON1</item>
        "$(printf "%s\n" "$MONS")"
      <variable>MON1</variable>
    </comboboxtext>"
else
    MONS0='' MONS1=''
fi

DEFRAD_NR=$(grep -n 'button {' ~/.config/sfwbar/sfwbar.config)
read -d ';' j DEFRAD <<<$(sed -n $((${DEFRAD_NR%%\:*} + 3))p $HOME/.config/sfwbar/sfwbar.config)
[[ ! $(echo "$DEFRAD" | grep '[0-9]') ]] && DEFRAD=0px
DEFSIZE=$(grep -o 'min-width.*;' $HOME/.config/sfwbar/logout.widget|grep -o '[0-9][0-9]px')

DEFRAD=${DEFRAD/px/}
DEFSIZE=${DEFSIZE/px/}

DEFLENGTH_NR=$(grep 'SetBarSize "panel"' $HOME/.config/sfwbar/sfwbar.config)
DEFLENGTH=$(echo $DEFLENGTH_NR | awk '{print $3}' | cut -d '"' -f2 | cut -d '"' -f1)
[ -z "$DEFLENGTH" ] && DEFLENGTH=100%

DEFITEMSIZE=$(grep '{ font:' $HOME/.config/sfwbar/sfwbar.config | awk '{print $4}' | sed 's/pt//g')
[ -z "$DEFITEMSIZE" ] && DEFITEMSIZE=10

GLOBAL=$(cat $HOME/.config/sfwbar/globalfont 2>/dev/null)
[ -z "$GLOBAL" ] && GLOBAL=false && echo $GLOBAL > $HOME/.config/sfwbar/globalfont

CSIZE=$(grep 'SIZE' $CONF|grep -o '[0-9][0-9]')

if [ "$FULL" = 'true' ]; then
    export SFWBAR_SPLASH='
<window title="SFWBar" icon-name="desktop_tray_config" resizable="false" decorated="false">'"
<vbox>
 <pixmap><input file>/usr/share/pixmaps/puppy/desktop_tray_config.svg</input><height>48</height><width>48</width></pixmap>
 <text use-markup=\"true\"><label>\"<b><span size='"'x-large'"'>          SFWBar Configuration          </span></b>\"</label></text>"'
 <text><label>'$(gettext 'Loading...')'</label></text>
</vbox></window>'
    gtkdialog --center -p SFWBAR_SPLASH &
    gpid=$!

    # current launchbar apps
    CLA=$(cat $HOME/.config/sfwbar/extrabar.conf | grep -v '=')
    if [ -n "$CLA" ]; then
        echo "$CLA" >> /tmp/sfwlaunchE.lst
        echo "$CLA" | cut -d'|' -f2- | cut -d'|' -f2 | while read LINE
        do
            [ -n "$LINE" ] && echo "$LINE ," >> /tmp/sfwlaunchEXTRA.lst
        done
    fi

    # available menu apps
    if [ ! -f $HOME/.config/sfwbar/sfwlaunchGUI.lst ]; then
        for i in /usr/share/applications/*; do
            grep -q "^Icon" $i || continue
            NAME="$(grep -m1 "^Name=" $i)"
            EXEC="$(grep -m1 "^Exec=" $i)"
            ICON="$(grep -m1 "^Icon=" $i)"
            echo "${ICON#*=}|${EXEC#*=}|${NAME#*=}" >> /tmp/sfwlaunch.lst
            echo "${NAME#*=} ," >> /tmp/sfwlaunchPRE.lst
        done
        cat /tmp/sfwlaunch.lst > $HOME/.config/sfwbar/sfwlaunch.lst
        sort /tmp/sfwlaunchPRE.lst > $HOME/.config/sfwbar/sfwlaunchGUI.lst
    fi

    kill -9 $gpid

    EXTRAS='<text use-markup="true"><label>"'$(gettext "<b>Launchers</b>")' "</label></text>
    <hbox space-expand="true" space-fill="true">
    <vbox width-request="255" space-expand="true" space-fill="true">
      <frame '$(gettext "Available Menu Applications  (select 2-24)")'>
        <tree sensitive="'"$SENSITIVE"'" space-expand="true" space-fill="true" enable-search="false" headers-visible="false">
         <variable>MENUAPP</variable>
         <input>cat $HOME/.config/sfwbar/sfwlaunchGUI.lst</input>
        </tree>
      </frame>
    </vbox>

    <vbox space-expand="false" space-fill="false">
    <text space-expand="false" space-fill="false" height-request="5" width-request="5"><label>" "</label></text>
    <hbox homogeneous="true" space-expand="false" space-fill="false">
        <button sensitive="'"$SENSITIVE"'" height-request="20" width-request="20" tooltip-text=" '$(gettext 'Update available menu applications')' ">
         <input file stock="gtk-refresh"></input>
         <action signal="button-release-event">rm -f $HOME/.config/sfwbar/sfwlaunchGUI.lst</action>
         <action signal="button-release-event">sfwbar-config.sh &</action>
         <action signal="button-release-event">exit:quit_now</action>
         <variable>UPDATE</variable>
        </button>
    </hbox>
    <hseparator></hseparator>
    <hbox homogeneous="true" space-expand="false" space-fill="false">
        <button sensitive="'"$SENSITIVE"'" height-request="20" width-request="20" tooltip-text=" '$(gettext 'Add selected menu application to launchbar')' ">
         <input file stock="gtk-add"></input>
         <action signal="button-release-event">echo $MENUAPP > /tmp/launcher_selected</action>
         <action signal="button-release-event">launcher_add</action>
         <action signal="button-release-event">refresh:LAUNCHERAPP</action>
         <variable>ADD</variable>
        </button>
    </hbox>
    <hbox homogeneous="true" space-expand="false" space-fill="false">
        <button sensitive="'"$SENSITIVE"'" height-request="20" width-request="20" tooltip-text=" '$(gettext 'Remove selected application from launchbar')' ">
         <input file stock="gtk-remove"></input>
         <action signal="button-release-event">launcher_remove</action>
         <action signal="button-release-event">refresh:LAUNCHERAPP</action>
         <variable>REMOVE</variable>
        </button>
    </hbox>
    <hseparator></hseparator>
    <hbox homogeneous="true" space-expand="false" space-fill="false">
        <button sensitive="'"$SENSITIVE"'" height-request="20" width-request="20" tooltip-text=" '$(gettext 'Move selected launcher up in list')' ">
         <input file stock="gtk-go-up"></input>
         <action signal="button-release-event">launcher_moveup</action>
         <action signal="button-release-event">refresh:LAUNCHERAPP</action>
         <variable>MOVEUP</variable>
        </button>
    </hbox>
    <hbox homogeneous="true" space-expand="false" space-fill="false">
        <button sensitive="'"$SENSITIVE"'" height-request="20" width-request="20" tooltip-text=" '$(gettext 'Move selected launcher down in list')' ">
         <input file stock="gtk-go-down"></input>
         <action signal="button-release-event">launcher_movedown</action>
         <action signal="button-release-event">refresh:LAUNCHERAPP</action>
         <variable>MOVEDOWN</variable>
        </button>
    </hbox>
    </vbox>

    <vbox width-request="255" space-expand="true" space-fill="true">
      <frame '$(gettext "LaunchBar Applications")'>
        <tree sensitive="'"$SENSITIVE"'" space-expand="true" space-fill="true" enable-search="false" headers-visible="false">
         <variable>LAUNCHERAPP</variable>
         <input>cat /tmp/sfwlaunchEXTRA.lst</input>
         <action signal="button-release-event">echo $LAUNCHERAPP > /tmp/launcher_selected</action>
        </tree>
      </frame>
    </vbox>
    </hbox>'

else
    EXTRAS=''
fi

[ "$FULL" = "true" ] && HEIGHT="600" || HEIGHT=""

# set header
mkdir -p /tmp/sfwbar
. /etc/DISTRO_SPECS
XML_INFO_COLOR='#EDEBD7' # background color
XML_INFO_OPACITY=0.5 # background opacity
. $HOME/.config/sfwbar/xml_info_sfwbar gtk > /dev/null # build bg_pixmap for gtk-theme

BOX_HEIGHT=90 # HEADER
ICON=/usr/share/pixmaps/puppy/desktop_tray_config.svg
ICON_HEIGHT=75
MSG_1="<b><span size='"'x-large'"'>$(gettext "SFWBar Configuration")</span></b>"
MSG_2="<b>$(gettext "TaskBar &amp; LaunchBar Settings")</b>"
MSG_3="<b>$DISTRO_NAME $DISTRO_VERSION</b>"
ALIGN=center # center or left
HEADER="
   <hbox space-expand="'"false"'" space-fill="'"false"'" height-request="'"${BOX_HEIGHT}"'">
   $(. $HOME/.config/sfwbar/xml_info_sfwbar "$ICON" "$ICON_HEIGHT" "$MSG_1" "$MSG_2" "$MSG_3" "$ALIGN")
   </hbox>"

# main dialog
export GUI='<window title="SFWBar Configuration" icon-name="desktop_tray_config" window-position="1">
  <vbox height-request="'"$HEIGHT"'" width-request="800">
  <vbox space-expand="true" space-fill="true">
  '$HEADER'
    <hbox space-expand="false" space-fill="false" homogeneous="true">
    <hbox space-expand="true" space-fill="true">
      <frame '$(gettext "TaskBar")'>
        <hbox>
            <text xalign="0"><label> '$(gettext "Screen position")'</label></text>
            <text space-expand="true" space-fill="true"><label>" "</label></text>
            <comboboxtext width-request="185" tooltip-text=" '$(gettext "Taskbar screen position")' ">
              <item>'$DEF_BARPOS'</item>
              <item>'$X_BARPOS'</item>
              <variable>BARPOS</variable>
            </comboboxtext>
            '$MONS0'
        </hbox>
        <hbox>
            <text xalign="0"><label> '$(gettext "Width & length")'</label></text>
            <text space-expand="true" space-fill="true"><label>" "</label></text>
            <comboboxtext width-request="90" tooltip-text=" '$(gettext "This option adjusts icon pixel size")' ">
              <default>'$DEFSIZE'</default>
              <item>24</item>
              <item>28</item>
              <item>30</item>
              <item>36</item>
              <item>42</item>
              <variable>NEWSIZE</variable>
            </comboboxtext>
            <comboboxtext width-request="90" tooltip-text=" '$(gettext "Taskbar length as percent of screen size")' ">
              <default>'$DEFLENGTH'</default>
              <item>100%</item>
              <item>90%</item>
              <item>80%</item>
              <item>70%</item>
              <variable>NEWLENGTH</variable>
            </comboboxtext>
        </hbox>
        <hbox space-expand="false" space-fill="false">
            <text xalign="0"><label> '$(gettext "Corner radius")'</label></text>
            <text space-expand="true" space-fill="true"><label>" "</label></text>
            <comboboxtext width-request="185" tooltip-text=" '$(gettext "Taskbar and Launchbar corner roundness  (0=square corners)")' ">
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
        <hbox space-expand="false" space-fill="false">
            <text xalign="0"><label> '$(gettext "Font size")'</label></text>
            <text space-expand="true" space-fill="true"><label>" "</label></text>
            <checkbox tooltip-text=" '$(gettext "Apply selected font size globally to desktop environment")' ">
              <label>'$(gettext "Global")'</label>
              <input>echo '$GLOBAL'</input>
              <variable>GLOBAL</variable>
            </checkbox>
            <comboboxtext width-request="185" tooltip-text=" '$(gettext "Apply selected font size to taskbar and desktop menus")' ">
              <default>'$DEFITEMSIZE'</default>
              <item>10</item>
              <item>11</item>
              <item>12</item>
              <item>13</item>
              <item>14</item>
              <variable>NEWITEMSIZE</variable>
            </comboboxtext>
        </hbox>
        <variable>ITEMS</variable>
      </frame>
    </hbox>

    <hbox space-expand="true" space-fill="true">
    <frame '$(gettext "LaunchBar")'>
        <hbox>
            <text xalign="0"><label> '$(gettext "Position & width")'</label></text>
            <text space-expand="true" space-fill="true"><label>" "</label></text>
            <comboboxtext sensitive="'"$SENSITIVE"'" tooltip-text=" '$(gettext "Launchbar screen position")' ">
              '$CITEMS'
              <variable>POS</variable>
            </comboboxtext>
            <comboboxtext sensitive="'"$SENSITIVE"'" tooltip-text=" '$(gettext "This option adjusts icon pixel size")' ">
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
        <hbox>
            <text xalign="0"><label> '$(gettext "Current launchers")'</label></text>
            <text space-expand="true" space-fill="true"><label>" "</label></text>
            <button sensitive="'"$SENSITIVE"'" space-expand="false" space-fill="false" tooltip-text=" '$(gettext 'Current launchbar applications')' ">
              <label> '$(gettext "List")'</label>
              <action>current_launchbar_apps &</action>
              <variable>LIST</variable>
            </button>
        </hbox>
        <text space-expand="false" space-fill="false"><label>" "</label></text>
        <hbox>
            <checkbox tooltip-text=" '$(gettext 'Visible or Autohide')' ">
              <label>'$(gettext "Toggle Visible/Autohide")'</label>
              <input>echo '$TOGGLE_VISIBLE'</input>
              <variable>TOGGLE_VISIBLE</variable>
              <action>if true toggle_visible</action>
              <action>refresh:LAUNCHERAPP</action>
            </checkbox>
            <text space-expand="true" space-fill="true"><label>" "</label></text>
        </hbox>
        <hbox>
            <checkbox tooltip-text=" '$(gettext 'Restore default launchbar applications')' ">
              <label>'$(gettext "Restore default launchbar")'</label>
              <input>echo '$DEFAULT_LAUNCHBAR'</input>
              <variable>DEFAULT_LAUNCHBAR</variable>
              <action>if true default_launchbar</action>
              <action>if false default_launchbar</action>
              <action>refresh:LAUNCHERAPP</action>
            </checkbox>
            <text space-expand="true" space-fill="true"><label>" "</label></text>
        </hbox>
        <hbox>
            <checkbox>
              <label>'$(gettext "Disable current launchbar")'</label>
              <input>echo '$STATE'</input>
              <variable>DISABLE</variable>
              <action>if true disable:POS</action>
              <action>if true disable:SIZE</action>
              <action>if true disable:MON1</action>
              <action>if true disable:LIST</action>
              <action>if true disable:MENUAPP</action>
              <action>if true disable:LAUNCHERAPP</action>
              <action>if true disable:UPDATE</action>
              <action>if true disable:ADD</action>
              <action>if true disable:REMOVE</action>
              <action>if true disable:MOVEUP</action>
              <action>if true disable:MOVEDOWN</action>
              <action>if true disable_launch_notification &</action>
              <action>if false enable:POS</action>
              <action>if false enable:SIZE</action>
              <action>if false enable:MON1</action>
              <action>if false enable:LIST</action>
              <action>if false enable:MENUAPP</action>
              <action>if false enable:LAUNCHERAPP</action>
              <action>if false enable:UPDATE</action>
              <action>if false enable:ADD</action>
              <action>if false enable:REMOVE</action>
              <action>if false enable:MOVEUP</action>
              <action>if false enable:MOVEDOWN</action>
              <action>if false enable_launch_notification &</action>
            </checkbox>
            <text space-expand="true" space-fill="true"><label>" "</label></text>
        </hbox>
        <variable>STOCK</variable>
      </frame>
    </hbox>
    </hbox>
    '$EXTRAS'
    <hbox space-expand="false" space-fill="false">
      <button width-request="26" space-expand="true" space-fill="true" tooltip-text=" '$(gettext 'Edit taskbar config')' ">
        <label> '$(gettext "Edit TaskBar Config")' </label>
        <input file stock="gtk-edit"></input>
        <action>defaulttexteditor --line=43 $HOME/.config/sfwbar/sfwbar.config &</action>
      </button>
      <button width-request="26" space-expand="true" space-fill="true" tooltip-text=" '$(gettext 'Set taskbar digital clock')' ">
        <label> '$(gettext "TaskBar Clock")' </label>
        <input file stock="gtk-execute"></input>
        <action>sfwbar-clockset &</action>
      </button>
      <button width-request="26" space-expand="true" space-fill="true" tooltip-text=" '$(gettext 'Update settings')' ">
        <label> '$(gettext "Update")' </label>
        <input file stock="gtk-apply"></input>
        <action>exit:ok</action>
      </button>
      <button width-request="26" space-expand="true" space-fill="true" tooltip-text=" '$(gettext 'Exit without updating')' ">
        <label> '$(gettext "Quit")' </label>
        <input file stock="gtk-quit"></input>
        <action>exit:quit_now</action>
      </button>
    </hbox>
  </vbox>
  </vbox>
</window>'

eval $(gtkdialog -p GUI --styles=/tmp/sfwbar/gtkrc_xml_info.css)
[ "$EXIT" = 'abort' -o "$EXIT" = 'quit_now' ] && exit

# set taskbar & launchbar corner roundness
if [ $RAD = 'default' ]; then
    RAD=$(grep -o '<cornerRadius>.*[0-9]' ~/.config/labwc/rc.xml | tail -c2)
    [ -z "$RAD" ] && RAD=0
fi
update_radii $DEFRAD $RAD

# set taskbar width (icon size)
update_size $NEWSIZE

# set global font size
if [ "$GLOBAL" = "true" ]; then
    echo "true" > $HOME/.config/sfwbar/globalfont
elif [ "$GLOBAL" = "false" ]; then
    echo "false" > $HOME/.config/sfwbar/globalfont
fi

# set menuitem size
update_menuitemsize $NEWITEMSIZE

# set taskbar length
sed -i "/SetBarSize \"panel\"/s/.*/  SetBarSize \"panel\", \"$NEWLENGTH\"/" $HOME/.config/sfwbar/sfwbar.config

# override selected launchbar position if same as taskbar
if [ "$POS" = "$BARPOS" ]; then
    if [ "$BARPOS" = "top" ]; then
        POS=bottom
    elif [ "$BARPOS" = "bottom" ]; then
        POS=top
    fi
    launchbar_position_override
fi

# taskbar position
if echo $TGT_STR | grep -qv "$BARPOS"; then
    orient_bar ${TGT_LN} $DEF_BARPOS $BARPOS #change orientation
fi
if ! grep -q "$BAR_MON" $HOME/.config/sfwbar/sfwbar.config ; then
    sed -i -e "s/#SetMonitor \"panel\".*$/SetMonitor \"panel\", \"$MON0\"/" -e "s/SetMonitor \"panel\".*$/SetMonitor \"panel\", \"$MON0\"/" $HOME/.config/sfwbar/sfwbar.config
fi

# enable/disable launchbar
CHECK=true
if [ "$DISABLE" = 'true' ]; then
    disable_launch
    exec $0 -fr
elif [ "$DISABLE" = 'false' ]; then
    # launcher
    enable_launch
    LAUNCHERS=`cat /tmp/sfwlaunchEXTRA.lst`
    echo "POS=$POS" > /tmp/sfwlaunchCONF.lst
    echo "SIZE=$SIZE" >> /tmp/sfwlaunchCONF.lst
    [ -n "$MON1" ] && echo "MON1=$MON1" >> /tmp/sfwlaunchCONF.lst
    rm -f /tmp/sfwlaunchSEL.lst

    # if no entries, add two default launchers
    [ -z "$LAUNCHERS" ] && LAUNCHERS="Default file manager ,
Log out ,"

    # count the entries
    NR=0
    if [ "$CHECK" = 'true' ]; then
        # count the entries
        echo $LAUNCHERS | tr ',' '\n' | while read LINE ; do
            NR=$(($NR + 1))
            echo $NR > /tmp/NR
            echo "$LINE" >> /tmp/sfwlaunchSEL.lst
            done
    fi
    NR=$((`cat /tmp/NR` - 1))
    ([ $NR -gt 24 ] || [ $NR -lt 2 ]) && gtkdialog-splash -bg pink -close box -text "$(gettext "Error: $NR entries. Please choose 2 or more or 24 or less.")" && exec $0
 
    # write config
    while read PROG ; do
        [ -n "$PROG" ] && parse_line "$PROG"
    done < /tmp/sfwlaunchSEL.lst
    cat /tmp/sfwlaunchCONF.lst > $CONF
    sfwlauncher

    exec $0 -er
fi
