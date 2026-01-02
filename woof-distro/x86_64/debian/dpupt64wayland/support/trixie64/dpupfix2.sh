#!/bin/sh
# further tweaks for Github version of TrixiePup64-Wayland executed inside sandbox3/rootfs-complete

sed -i 's%no_single_hover=0%no_single_hover=1%' root/.config/spacefm/session
sed -i 's%no_single_hover=0%no_single_hover=1%' root/.config/spacefm/session-default
sed -i 's%</keyboard>%<keybind key="A-z"><action name="Execute"><command>/usr/bin/touchpad-toggle.sh</command></action></keybind></keyboard>%' root/.config/labwc/rc.xml

# temp
( cd root/Desktop
mv browse.desktop browse_app.desktop
mv file.desktop file_app.desktop
mv settings.desktop setup_app.desktop
sed -i 's%=Settings%=Setup%' setup_app.desktop
mv terminal.desktop terminal_app.desktop
mv trash.desktop trash_app.desktop
)

echo '1=file_app.desktop
2=terminal_app.desktop
3=browse_app.desktop
4=setup_app.desktop
5=trash_app.desktop' > root/.config/zzzfm/desktop0

echo 'minimalapps' > root/.config/zzzfm/applayout

# end temp

exit 0
