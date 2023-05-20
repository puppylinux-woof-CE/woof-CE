# XDG_CURRENT_DESKTOP has the same value as under labwc
cat << EOF >> etc/environment
XDG_CURRENT_DESKTOP=wlroots
XWAYLAND_SCREENSAVER_DELAY=600
EOF

if [ -f usr/bin/jwm ]; then
	cat << EOF >> etc/environment
DWL_BORDER_COLOR=#000000
DWL_FOCUS_COLOR=#000000
DWL_ROOT_COLOR=#000000
GDK_BACKEND=x11
QT_QPA_PLATFORM=xcb
SDL_VIDEODRIVER=x11
EOF
else
	cat << EOF >> etc/environment
DWL_BORDER_COLOR=#000000
DWL_FOCUS_COLOR=#FF00FF
DWL_ROOT_COLOR=#221111
EOF
fi

[ -f root/.jwm/jwmrc-personal ] && sed -i 's~^<Key key="Print">exec:defaultscreenshot</Key>$~&\n<Key mask="S" key="Print">exec:slurp-screenshot</Key>~' root/.jwm/jwmrc-personal
