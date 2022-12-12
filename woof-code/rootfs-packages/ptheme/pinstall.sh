# pinstall for ptheme
############################################################################
echo

#--- test
[ -f ../../_00build.conf ] && . ../../_00build.conf # main woof - pwd -> sandbox3/rootfs-complete
[ -f ../../_00build_2.conf ] && . ../../_00build_2.conf # main woof - pwd -> sandbox3/rootfs-complete - override main settings
[ -f ../build.conf ] && . ../build.conf # zwn - pwd -> $CHROOT_DIR
#--

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
fi

[ "$theme" = "" ] && rm -rf usr/sbin/ptheme usr/share/ptheme usr/share/applications/ptheme.desktop || (
if [ ! -f usr/share/ptheme/globals/"${theme}" ];then
	echo "Invalid theme: $theme - defaulting to Original Pup"
	theme="Original Pup"
fi
echo "Setting $theme to default"
echo
echo "see $PWD/usr/share/ptheme/globals for available themes"
echo "that you can specify in build.conf: PTHEME=<theme>"

. usr/share/ptheme/globals/"${theme}"

##### JWM
[ ! -d root/.jwm ] && mkdir -p root/.jwm
cp -af usr/share/jwm/themes/"${PTHEME_JWM_COLOR}-jwmrc" root/.jwm/jwmrc-theme
echo "jwm colors: ${PTHEME_JWM_COLOR}"

cp -f usr/share/jwm/tray_templates/"$PTHEME_JWM_TRAY"/jwmrc-tray* root/.jwm/
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
if [ "$PTHEME_JWM_BUTTONS" = "default" ]; then
    sed -i -e '/^<ButtonClose>/d' -e '/^<ButtonMax>/d' -e '/^<ButtonMaxActive>/d' -e '/^<ButtonMin>/d' root/.jwm/jwmrc-personal
else
    Dir=usr/share/jwm/themes_window_buttons/${PTHEME_JWM_BUTTONS}
    for icon in $Dir/*; do
        ifile=$(basename $icon)
        ext=${ifile##*.}
        newicon=`echo $ifile|sed "s%${ext}$%png%"`
        if [ "`which rsvg-convert`" ]; then
            rsvg-convert -w 48 -h 48 -o root/.jwm/window_buttons/${newicon} ${icon}
        else
            chroot . rsvg-convert -w 48 -h 48 -o root/.jwm/window_buttons/${newicon} /${icon}
        fi
    done
fi
echo "jwm buttons: ${PTHEME_JWM_BUTTONS}"

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
gtk-toolbar-style = GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size = GTK_ICON_SIZE_LARGE_TOOLBAR
_EOF
if [ -d usr/share/themes/${PTHEME_GTK}/gtk-3.0 ]; then
	mkdir -p root/.config/gtk-3.0
	cat > root/.config/gtk-3.0/settings.ini << _EOF
[Settings]
gtk-theme-name = ${PTHEME_GTK}
gtk-toolbar-style = GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size = GTK_ICON_SIZE_LARGE_TOOLBAR
_EOF
fi
if [ -d usr/share/themes/${PTHEME_GTK}/gtk-4.0 ]; then
	mkdir -p root/.config/gtk-4.0
	cat > root/.config/gtk-4.0/settings.ini << _EOF
[Settings]
gtk-theme-name = ${PTHEME_GTK}
_EOF
fi

echo "gtk: ${PTHEME_GTK}"

# icon theme
if [ -n "$PTHEME_ICONS_GTK" ] ; then
	USE_ICON_THEME="`find usr/share/icons -maxdepth 1 -type d -name "$PTHEME_ICONS_GTK"`"
fi
if [ -z "$USE_ICON_THEME" ] ; then
	USE_ICON_THEME="Puppy Standard"
else
	USE_ICON_THEME="$PTHEME_ICONS_GTK" # default if exists
fi
if [ -d "usr/share/icons/$USE_ICON_THEME" ];then
	# first global
	echo -e "gtk-icon-theme-name = \"$USE_ICON_THEME\"" >> root/.gtkrc-2.0
	if [ -f root/.config/gtk-3.0/settings.ini ]; then
		echo -e "gtk-icon-theme-name = $USE_ICON_THEME" >> root/.config/gtk-3.0/settings.ini
		# fix for menuitem and button icons
		cat >> root/.config/gtk-3.0/settings.ini <<EOF
gtk-menu-images = 1
gtk-button-images = 1				
gtk-enable-animations = 0
EOF
	fi
	if [ -f root/.config/gtk-4.0/settings.ini ]; then
		echo -e "gtk-icon-theme-name = $USE_ICON_THEME" >> root/.config/gtk-4.0/settings.ini
		cat >> root/.config/gtk-4.0/settings.ini <<EOF
gtk-enable-animations = 0
EOF
	fi
	# then ROX
	ROX_THEME_FILE="root/.config/rox.sourceforge.net/ROX-Filer/Options" # this could change in future
	sed -i "s%<Option name=\"icon_theme\">.*%<Option name=\"icon_theme\">$USE_ICON_THEME</Option>%" $ROX_THEME_FILE
	echo "icon theme: $USE_ICON_THEME"
fi

install -D -m 644 root/.gtkrc-2.0 etc/gtk-2.0/gtkrc
if [ -f root/.config/gtk-3.0/settings.ini ]; then
	install -D -m 644 root/.config/gtk-3.0/settings.ini etc/gtk-3.0/settings.ini
	install -D -m 644 -o spot -g spot root/.config/gtk-3.0/settings.ini home/spot/.config/gtk-3.0/settings.ini
fi
if [ -f root/.config/gtk-4.0/settings.ini ]; then
	install -D -m 644 root/.config/gtk-4.0/settings.ini etc/gtk-4.0/settings.ini
	install -D -m 644 -o spot -g spot root/.config/gtk-4.0/settings.ini home/spot/.config/gtk-4.0/settings.ini
fi

##### WALLPAPER #copy it as mv messes the themes
ext="${PTHEME_WALL##*.}"
cp -af usr/share/backgrounds/"${PTHEME_WALL}" usr/share/backgrounds/default.${ext}
echo "wallpaper: ${PTHEME_WALL}"
# record the changes
WDIR=root/.config/wallpaper
mkdir -p $WDIR
echo "Stretch" > ${WDIR}/backgroundmode
echo "/usr/share/backgrounds" > ${WDIR}/bgdir
echo "/usr/share/backgrounds/default.${ext}" > ${WDIR}/bg_img
echo "defaultpaint" > ${WDIR}/EDITOR
echo "rox" > ${WDIR}/FILER
echo "FILER="rox"
IMGEDITOR="defaultpaint"
INT="5"
SLIDEDIR="/usr/share/backgrounds"
VIEWER="defaultimageviewer"
EXIT="Close"
" > ${WDIR}/preferences
echo "defaultimageviewer" > ${WDIR}/VIEWER

##### ROX
BACKDROP="  <backdrop style=\"Stretched\">/usr/share/backgrounds/default.${ext}</backdrop>"
echo -e '<?xml version="1.0"?>\n<pinboard>' > /tmp/newpin
echo "$BACKDROP" >> /tmp/newpin
cat usr/share/ptheme/rox_pinboard/"${PTHEME_ROX_PIN}" >> /tmp/newpin
echo '</pinboard>' >> /tmp/newpin
cp -a /tmp/newpin root/Choices/ROX-Filer/PuppyPin
echo "rox icons arrangement (apps): ${PTHEME_ROX_PIN}"

#drive icons
if [ "$PTHEME_ROX_DRIVEICONS" ]; then
	for I in ICON_PLACE_EDGE_GAP ICON_PLACE_START_GAP ICON_PLACE_SPACING ICON_PLACE_ORIENTATION; do
		TMP="`grep "^$I" etc/eventmanager`"
		VALUE="`grep "^$I" "usr/share/ptheme/eventmanager_driveicons/${PTHEME_ROX_DRIVEICONS}" | cut -d= -f2`"
		[ ! "$VALUE" ] && continue
		sed -i "s/${TMP}/${I}=${VALUE}/" etc/eventmanager
	done
fi

echo "rox icons arrangement (drives): ${PTHEME_ROX_DRIVEICONS}"

##### ICONS
echo -n "${PTHEME_ICONS}" > etc/desktop_icon_theme
echo "icons: ${PTHEME_ICONS}"

##### CURSOR
mkdir -p root/.icons/
if [ ! "`grep 'ORIGINAL THEME' <<< "$PTHEME_MOUSE"`" ] ; then
	mkdir -p home/spot/.icons
	rm -f root/.icons/default home/spot/.icons/default
	if [ -d usr/share/icons/$PTHEME_MOUSE ]; then
		ln -snf /usr/share/icons/$PTHEME_MOUSE root/.icons/default
		ln -s /usr/share/icons/$PTHEME_MOUSE home/spot/.icons/default
	else
		ln -snf $PTHEME_MOUSE root/.icons/default
		ln -s ../../../root/.icons/default home/spot/.icons/ # this won't work
	fi
	chroot . chown -R spot:spot /home/spot/.icons
fi
echo "cursor: ${PTHEME_MOUSE}"

##### GTKDIALOG
[ -d root/.config/ptheme/ ] || mkdir -p root/.config/ptheme/
cp -f "usr/share/ptheme/gtkdialog/$PTHEME_GTKDIALOG" root/.config/ptheme/gtkdialog_active
echo "gtkdialog: ${PTHEME_GTKDIALOG}"

#### update JWMRC
#JWMRCVER=$(grep JWMRC_VERSION etc/xdg/templates/_root_.jwmrc | cut -f 4 -d '_' | cut -f 1 -d ' ')
#UPDATEVER=$(grep JWMRC_VERSION etc/rc.d/rc.update | cut -f 3 -d '_' | cut -f 1 -d ' ')
#[ "$JWMRCVER" != "$UPDATEVER" ] && sed -i "s/$UPDATEVER/$JWMRCVER/" etc/rc.d/rc.update

# pt_buntoo
[ -f etc/DISTRO_SPECS ] && . etc/DISTRO_SPECS
BUN=buntoo.svg
(
cd usr/share/backgrounds
if [ -f "${DISTRO_FILE_PREFIX}-wall2.svg" ];then
	mv -f $BUN obuntoo.svg
	cp -af "${DISTRO_FILE_PREFIX}-wall2.svg" $BUN
fi
)

# pt_faux_xfwm
XF=xfwallpaper.svg
(
cd usr/share/backgrounds
if [ -f "${DISTRO_FILE_PREFIX}-wall1.svg" ];then
	mv -f $XF oxfwallpaper.svg
	cp -af "${DISTRO_FILE_PREFIX}-wall1.svg" $XF
fi
)

sync
echo "done"
echo
echo
)
