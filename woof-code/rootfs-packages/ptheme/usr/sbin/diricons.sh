#!/bin/ash
# called from ptheme_gtk
# link special theme icons to */.DirIcon

[ -e "$HOME/.config/gtk-3.0/settings.ini" ] && \
	ICON_THEME="$(grep "gtk-icon-theme-name" $HOME/.config/gtk-3.0/settings.ini)" \
	|| exit
ICON_THEME="${ICON_THEME##*=}"
ICON_THEME="${ICON_THEME/ /}"

# link
ln_diricon() {
	EPATH=$1
	ICON=$2
	[ -e "$ICON" ] && \
		(cd "$EPATH"; ln -svf "$ICON" ./.DirIcon )
}

for icon in $(ls "/usr/share/icons/$ICON_THEME/48/places/" | grep "^directory");do
	if echo $icon|grep -q 'directory-home' ;then
			ln_diricon "$HOME" "/usr/share/icons/$ICON_THEME/48/places/$icon"
			continue # home
	else
		for dir in Documents Downloads my-documents my-applications network Music Video Images ; do
			[ "$dir" = 'network' ] && i=remote || i=$dir
			[ -e "$HOME/$dir" ] && ICON=`echo $icon|grep -i "${i#*-}"`
			[ -n "$ICON" ] && ln_diricon "$HOME/$dir"  "/usr/share/icons/$ICON_THEME/48/places/$ICON" 
		done
	fi
done
