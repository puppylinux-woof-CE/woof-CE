#!/bin/sh
echo '#!/bin/sh
exec firefox "$@"' > usr/local/bin/defaultbrowser
chmod 755 usr/local/bin/defaultbrowser
echo '#!/bin/sh
exec firefox "$@"' > usr/local/bin/defaulthtmlviewer
chmod 755 usr/local/bin/defaulthtmlviewer
echo "setting up Firefox"
