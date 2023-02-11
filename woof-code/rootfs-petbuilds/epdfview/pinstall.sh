echo '#!/bin/sh
exec epdfview "$@"' > usr/local/bin/defaultpdfviewer
chmod 755 usr/local/bin/defaultpdfviewer
