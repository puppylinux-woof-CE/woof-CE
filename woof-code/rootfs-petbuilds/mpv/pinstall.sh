echo '#!/bin/ash
[ $# -eq 0 ] && exec mpv --player-operation-mode=pseudo-gui
exec mpv "$@"' > usr/local/bin/defaultmediaplayer
chmod 755 usr/local/bin/defaultmediaplayer

if [ -f usr/bin/dwl -a -f usr/bin/jwm ]; then
	mkdir -p usr/libexec/mpv
	mv -f usr/bin/mpv usr/libexec/mpv/
	echo '#!/bin/ash
[ "$GDK_BACKEND" = "x11" ] && WAYLAND_DISPLAY= exec /usr/libexec/mpv/mpv "$@"
exec /usr/libexec/mpv/mpv "$@"' > usr/bin/mpv
	chmod 755 usr/bin/mpv
fi
