# pinstall for ptheme
############################################################################
echo

for dtop in switch2 GTK-Chtheme icon_switcher; do
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
if [ -z "$theme" ];then
    theme=Stardust_bright_mouse
    echo "OK, you didn't choose, defaulting to $theme"
fi
echo "Setting $theme to default"

. usr/share/ptheme/globals/"${theme}"



##### JWM
cp -af usr/share/jwm/themes/"${PTHEME_JWM_COLOR}-jwmrc" root/.jwm/jwmrc-theme
cp -af usr/share/jwm/themes/"${PTHEME_JWM_COLOR}-colors" root/.jwm/jwm_colors
echo "jwm colors: ${PTHEME_JWM_COLOR}"

cp -f usr/share/jwm/tray_templates/"$PTHEME_JWM_TRAY"/jwmrc-tray* root/.jwm/
echo "jwm tray: ${PTHEME_JWM_TRAY}"

case $PTHEME_JWM_SIZE in
small) rm root/.jwm/menuheights;;
normal) echo "MENHEIGHT=24" > root/.jwm/menuheights;;
large) echo "MENHEIGHT=32" > root/.jwm/menuheights;;
huge) echo "MENHEIGHT=40" > root/.jwm/menuheights;;
esac
echo "jwm size: ${PTHEME_JWM_SIZE}"

mkdir root/.jwm/window_buttons
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
sleep 1 # reading time



##### WALLPAPER
ext="${PTHEME_WALL##*.}"
mv -f usr/share/backgrounds/"${PTHEME_WALL}" usr/share/backgrounds/default.${ext}
echo "wallpaper: ${PTHEME_WALL}"
sleep 1 # reading time



##### ROX
BACKDROP="  <backdrop style=\"Stretched\">/usr/share/backgrounds/default.${ext}</backdrop>"
echo -e '<?xml version="1.0"?>\n<pinboard>' > /tmp/newpin
echo "$BACKDROP" >> /tmp/newpin
cat usr/share/ptheme/rox_pinboard/"${PTHEME_ROX_PIN}" >> /tmp/newpin
echo '</pinboard>' >> /tmp/newpin
cp -a /tmp/newpin root/Choices/ROX-Filer/PuppyPin
echo "rox: ${PTHEME_ROX_PIN}"
sleep 1 # reading time



##### ICONS
echo -n "${PTHEME_ICONS}" > etc/desktop_icon_theme
echo "icons: ${PTHEME_ICONS}"
sleep 1 # reading time



##### CURSOR
if [ -d root/.icons/ ];then
	[ ! "`grep 'ORIGINAL THEME' <<< "$PTHEME_MOUSE"`" ] && ln -snf root/.icons/$PTHEME_MOUSE root/.icons/default
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

echo "done"
echo
echo
