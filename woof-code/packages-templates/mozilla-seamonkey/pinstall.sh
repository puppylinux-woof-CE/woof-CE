#!/bin/sh
echo '#!/bin/sh
exec seamonkey "$@"' > usr/local/bin/defaultbrowser
chmod 755 usr/local/bin/defaultbrowser
echo '#!/bin/sh
exec seamonkey "$@"' > usr/local/bin/defaulthtmlviewer
chmod 755 usr/local/bin/defaulthtmlviewer
echo "setting up SeaMonkey browser"
echo '#!/bin/sh
exec seamonkey -mail "$@"' > usr/local/bin/defaultemail
chmod 755 usr/local/bin/defaultemail
echo "setting up SeaMonkey email"
