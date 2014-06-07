wvdial and wvdial-pipe are supposed to be inside 'peers' directory,
however that conflicts with gkdial.

Therefore, /usr/sbin/gnomepppshell (gnome_ppp package, the GUI for wvdial)
moves these files into peers then back out afterward.
