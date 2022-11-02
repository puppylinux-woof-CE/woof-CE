[ -f root/.spot-status ] && mv -f root/.spot-status root/.spot-status.orig
chroot . /usr/sbin/setup-spot connman-ui-gtk=true
[ -f root/.spot-status.orig ] && mv -f root/.spot-status.orig root/.spot-status || rm -f root/.spot-status
