mv -f root/.spot-status root/.spot-status.orig
chroot . /usr/sbin/setup-spot pa-applet=true
mv -f root/.spot-status.orig root/.spot-status
