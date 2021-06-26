[ -f root/.spot-status ] && mv -f root/.spot-status root/.spot-status.orig
chroot . /usr/sbin/setup-spot pa-applet=true
[ -f root/.spot-status.orig ] && mv -f root/.spot-status.orig root/.spot-status || rm -f root/.spot-status
