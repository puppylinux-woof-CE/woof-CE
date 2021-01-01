This is a fork of Barry's "network_tray" since it uses different icons
and has a few bugs fixed. It also incorporates Patriot's "Lame Wifi", so that 
if you are connected by wifi you will get signal strength icons in the tray
and tooltip. The tooltip also shows the interface address (eg: eth0, eth1 wlan0)
and your current IPv4 address.

It also incorporates new libraries since Barry's version relied on dirent.h to 
open the relevant files for reading. I have included arpa/inet.h, ifaddrs.h
and netinet/in.h to gain access to the structures that hold the interface
info and the IP address. Patriot's Lame Wifi also adds the linux/wireless.h
dependency and sys/ioctl.h.

While this does make the executable bigger (~17KB[32] ~20KB[64] stripped) I think
the gains in versatility, stability* and reliability* (* to be proven) are worth 
it in the long run.

To build the exec just type 'make' at the cli. Of course devx must be loaded.
Install the exec to your PATH (or $HOME/Startup). The .desktop is provided for 
recent woof puppies to be installed to $HOME/.config/autostart.

A .pot file is included for translators. The code is i18n/gettext compliant.

Install the icons to /usr/share/pixmaps/puppy 

The exec is designed to run when your window manager starts (either by new woof
method of adding the supplied .desktop file and placing in $HOME/.config/autostart
or symlinking the exec to /root/Starup)

The program now has wireless polling off by default, toggled in the right click
menu. There is a mechanism whereby you can start the program in wireless polling
mode from a symlink to the exec named "netmon_wpoll" (or rename the exec). If you 
do this then edit the .desktop file or the symlink in /root/Startup must be 
name "netmon_wpoll".


GPL2 or later at your discretion.

NO WARRANTY!!!

01micko@gmail.com
