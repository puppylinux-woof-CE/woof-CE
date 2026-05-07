#!/bin/sh
# further tweaks for Github version of TrixiePup64-Wayland executed inside sandbox3/rootfs-complete

. etc/DISTRO_SPECS
sed -i -e "s/Dpup-10.0/$DISTRO_NAME-$DISTRO_VERSION/g" usr/share/doc/index.html
rm usr/share/doc/release-Dpup-10.0.htm

sed -i 's%no_single_hover=0%no_single_hover=1%' root/.config/spacefm/session
sed -i 's%no_single_hover=0%no_single_hover=1%' root/.config/spacefm/session-default
sed -i 's%</keyboard>%<keybind key="A-z"><action name="Execute"><command>/usr/bin/touchpad-toggle.sh</command></action></keybind></keyboard>%' root/.config/labwc/rc.xml
sed -i 's%layout {%layout {  include ("cpu.widget")%' root/.config/sfwbar/includes.widget
exit 0
