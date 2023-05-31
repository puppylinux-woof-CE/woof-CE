echo '#!/bin/sh
exec spacefm "$@"' > usr/local/bin/defaultfilemanager
chmod 755 usr/local/bin/defaultfilemanager

echo none > etc/desktop_app

chroot . xdg-mime default spacefm.desktop inode/directory
chroot . run-as-spot xdg-mime default spacefm.desktop inode/directory
