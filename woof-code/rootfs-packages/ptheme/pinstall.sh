# pinstall for ptheme
############################################################################
echo

for dtop in switch2 GTK-Chtheme icon_switcher Desktop-drive-icons; do
    [ -f "usr/share/applications/${dtop}.desktop" ] || continue
    if grep -q "^NoDisplay" usr/share/applications/${dtop}.desktop; then
        sed -i 's%NoDisplay=.*%NoDisplay=true%' usr/share/applications/${dtop}.desktop
    else
        echo 'NoDisplay=true' >> usr/share/applications/${dtop}.desktop
    fi
done

# poor man's pTheme!
# choose a global theme
############################################################################

#woof-code/_00build.conf
#the PTHEME variable con be specified in build.conf
if [ "$PTHEME" != "" ] ; then
	theme="$PTHEME"
else
	echo
	[ -f /tmp/ptheme_choose ] && rm /tmp/ptheme_choose
	echo "You can choose from the following global themes"
	echo
	num=1
	while read i; do
		echo "$num $i"
		echo "$num $i" >> /tmp/ptheme_choose
		num=$(($num + 1))
	done <<< "`ls usr/share/ptheme/globals`"
	echo
	echo "Type the number of the theme you want"

	xnum=1
	theme=""
	while [ $xnum -lt 4 ];do
		read ptheme_num
		echo "$ptheme_num" | grep -qv '[0-9]' && echo "A number is needed" && continue
		if grep -q ${ptheme_num} /tmp/ptheme_choose;then
			theme=`grep -w "${ptheme_num}" /tmp/ptheme_choose|cut -d ' ' -f2,3,4`
			echo "You chose ${theme}. Excellent choice."
			break
		else
			if [ $xnum -lt 3 ];then
				echo "Sorry, that didn't work, try another number"
			else
				echo "Last chance..."
			fi
			xnum=$(($xnum + 1))
		fi
	done
fi

if [ ! -f usr/share/ptheme/globals/"${theme}" ];then
    theme="Bright Mouse"
    echo "Invalid theme, defaulting to $theme"
fi
echo "Setting $theme to default"

. usr/share/ptheme/globals/"${theme}"


##### JWM
cp -af usr/share/jwm/themes/"${PTHEME_JWM_COLOR}-jwmrc" root/.jwm/jwmrc-theme
#cp -af usr/share/jwm/themes/"${PTHEME_JWM_COLOR}-colors" root/.jwm/jwm_colors
echo "jwm colors: ${PTHEME_JWM_COLOR}"

cp -f usr/share/jwm/tray_templates/"$PTHEME_JWM_TRAY"/jwmrc-tray* root/.jwm/
[ ! -d root/.jwm ] && mkdir root/.jwm
#hybrid
rm -f root/.jwm/jwmrc-tray*_hybrid
for I in 1 2 3 4; do
	if [ "`grep -F '_hybrid</Include>' root/.jwm/jwmrc-tray$I`" ]; then
		grep -vF '_hybrid</Include>' root/.jwm/jwmrc-tray$I | sed -e 's%autohide="\(top\|bottom\|left\|right\)" %autohide="off"%' -e "s%layer=\"above\"%layer=\"below\"%" > root/.jwm/jwmrc-tray${I}_hybrid
	fi
done
#---
echo "$PTHEME_JWM_TRAY" > root/.jwm/tray_active_preset
echo "jwm tray: ${PTHEME_JWM_TRAY}"

# make new default the backup
cp -af root/.jwm/jwmrc-tray* root/.jwm/backup/
cp -af root/.jwm/jwmrc-theme root/.jwm/backup/

case $PTHEME_JWM_SIZE in
small) rm root/.jwm/menuheights;;
normal) echo "MENHEIGHT=24" > root/.jwm/menuheights;;
large) echo "MENHEIGHT=32" > root/.jwm/menuheights;;
huge) echo "MENHEIGHT=40" > root/.jwm/menuheights;;
*) echo "MENHEIGHT=24" > root/.jwm/menuheights;; # default
esac
echo "jwm size: ${PTHEME_JWM_SIZE}"

mkdir -p root/.jwm/window_buttons
Dir=usr/share/jwm/themes_window_buttons/${PTHEME_JWM_BUTTONS}
for icon in $Dir/*; do
    ifile=$(basename $icon)
    ext=${ifile##*.}
    newicon=`echo $ifile|sed "s%${ext}$%png%"`
    #JWM does a crappy svg convert, so we help out if rsvg-convert is installed
    if [ "`which rsvg-convert`" ]; then
        rsvg-convert -w 48 -h 48 -o root/.jwm/window_buttons/${newicon} ${icon}
    else
        ln -sf ${icon} root/.jwm/window_buttons/${newicon}
    fi
done
echo "jwm buttons: ${PTHEME_JWM_BUTTONS}"
sleep 1 # reading time



##### GTK
cat > root/.gtkrc-2.0 << _EOF
# -- THEME AUTO-WRITTEN BY gtk-theme-switch2 DO NOT EDIT
include "/usr/share/themes/${PTHEME_GTK}/gtk-2.0/gtkrc"

style "user-font"
{
  font_name=""
}
widget_class "*" style "user-font"

include "/root/.gtkrc-2.0.mine"

# -- THEME AUTO-WRITTEN BY gtk-theme-switch2 DO NOT EDIT
gtk-theme-name = "${PTHEME_GTK}"
_EOF
echo "gtk: ${PTHEME_GTK}"

# icon theme
[ -n "$PTHEME_ICONS_GTK" ] && \
USE_ICON_THEME="`find usr/share/icons -type d -name "$PTHEME_ICONS_GTK" -maxdepth 1`"
[ -z "$USE_ICON_THEME" ] && USE_ICON_THEME="Puppy Standard" # default if exists
if [ -d "usr/share/icons/$USE_ICON_THEME" ];then
	# first global
	echo -e "gtk-icon-theme-name = \"$USE_ICON_THEME\"" >> root/.gtkrc-2.0
	# then ROX
	ROX_THEME_FILE="root/.config/rox.sourceforge.net/ROX-Filer/Options" # this could change in future
	sed -i "s%ROX%$USE_ICON_THEME%" $ROX_THEME_FILE
	echo "icon theme: $USE_ICON_THEME"
fi

sleep 1 # reading time

##### WALLPAPER #copy it as mv messes the themes
ext="${PTHEME_WALL##*.}"
cp -af usr/share/backgrounds/"${PTHEME_WALL}" usr/share/backgrounds/default.${ext}
echo "wallpaper: ${PTHEME_WALL}"
sleep 1 # reading time



##### ROX
BACKDROP="  <backdrop style=\"Stretched\">/usr/share/backgrounds/default.${ext}</backdrop>"
echo -e '<?xml version="1.0"?>\n<pinboard>' > /tmp/newpin
echo "$BACKDROP" >> /tmp/newpin
cat usr/share/ptheme/rox_pinboard/"${PTHEME_ROX_PIN}" >> /tmp/newpin
echo '</pinboard>' >> /tmp/newpin
cp -a /tmp/newpin root/Choices/ROX-Filer/PuppyPin
echo "rox icons arrangement (apps): ${PTHEME_ROX_PIN}"
sleep 1 # reading time

#drive icons
if [ "$PTHEME_ROX_DRIVEICONS" ]; then
	for I in ICONDESK ICONPARTITIONS LABELPARTITIONS ICON_PLACE_EDGE_GAP ICON_PLACE_START_GAP ICON_PLACE_SPACING ICON_PLACE_ORIENTATION; do
		TMP="`grep "^$I" etc/eventmanager`"
		VALUE="`grep "^$I" "usr/share/ptheme/eventmanager_driveicons/${PTHEME_ROX_DRIVEICONS}" | cut -d= -f2`"
		[ ! "$VALUE" ] && continue
		sed -i "s/${TMP}/${I}=${VALUE}/" etc/eventmanager
	done
fi
echo "rox icons arrangement (drives): ${PTHEME_ROX_DRIVEICONS}"
sleep 1 # reading time



##### ICONS
echo -n "${PTHEME_ICONS}" > etc/desktop_icon_theme
echo "icons: ${PTHEME_ICONS}"
sleep 1 # reading time



##### CURSOR
if [ -d root/.icons/ ];then
	[ ! "`grep 'ORIGINAL THEME' <<< "$PTHEME_MOUSE"`" ] && ln -snf $PTHEME_MOUSE root/.icons/default
	echo "cursor: ${PTHEME_MOUSE}"
	sleep 1 # reading time
fi



##### GTKDIALOG
[ -d root/.config/ptheme/ ] || mkdir -p root/.config/ptheme/
cp -f "usr/share/ptheme/gtkdialog/$PTHEME_GTKDIALOG" root/.config/ptheme/gtkdialog_active
echo "gtkdialog: ${PTHEME_GTKDIALOG}"
sleep 1 # reading time

#### update JWMRC
JWMRCVER=$(grep JWMRC_VERSION etc/xdg/templates/_root_.jwmrc | cut -f 4 -d '_' | cut -f 1 -d ' ')
UPDATEVER=$(grep JWMRC_VERSION etc/rc.d/rc.update | cut -f 3 -d '_' | cut -f 1 -d ' ')
[ "$JWMRCVER" != "$UPDATEVER" ] && sed -i "s/$UPDATEVER/$JWMRCVER/" etc/rc.d/rc.update

sync
echo "done"
echo
echo
