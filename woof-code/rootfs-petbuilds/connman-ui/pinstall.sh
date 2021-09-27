echo -e '#!/bin/sh\nexec connman-ui-gtk' > usr/local/bin/defaultconnect
chmod 755 usr/local/bin/defaultconnect

echo "CURRENT_EXEC=connman-ui-gtk" > root/.connectwizardrc

[ -f root/.spot-status ] && mv -f root/.spot-status root/.spot-status.orig
chroot . /usr/sbin/setup-spot connman-ui-gtk=true
[ -f root/.spot-status.orig ] && mv -f root/.spot-status.orig root/.spot-status || rm -f root/.spot-status
