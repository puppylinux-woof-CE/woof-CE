FIREWALL-STATUS
---------------

A gtk status icon for your firewall.

REQUIRES:
gtk+-2.0 >= 2.20(?) (does not support egg-tray-icon of early gtk2)
rsvg
a window manager panel with a tray (jwm or lxpanel work well)

GPL-V2 (see LICENCE.txt)
Originally firewallstate by Rob Lane, tasmod @ murga forum
Original at http://murga-linux.com/puppy/viewtopic.php?p=434498#434498
(c) Rob Lane 2010-2014
Redesigned by 01micko, 01micko@gmail.com
i18n by rodin.s @ murga forum

NO WARRANTY!

Icons are hard coded in the source to :
/usr/share/pixmaps/puppy/shield_yes.svg (line 67)
and
/usr/share/pixmaps/puppy/shield_no.svg (line 74)
*line numbers may change
These icons are part of woof. You can get them from :
https://github.com/puppylinux-woof-CE/woof-CE
For your convenience they are supplied with this source.
Change it to suit yourself or your distro. You can use other formats (png, xpm).
This program runs as root!

BUILD
-----

-remove any previous build, package and package tree by hand
-run:
./build.sh

 #############################################################################
NOTE! this does NOT copy the .desktop file! 
It is NOT to go to /usr/share/applications!!
It goes in /root/.config/autostart/

 #############################################################################
 
If you want a pet then run "dir2pet directory-name",
where "directory-name" is "firewall-monitor-version-arch".
Have fun!
