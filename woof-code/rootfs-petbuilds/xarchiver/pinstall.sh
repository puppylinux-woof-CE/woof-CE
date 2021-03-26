echo '#!/bin/sh
exec xarchiver "$@"' > usr/local/bin/defaultarchiver
chmod 755 usr/local/bin/defaultarchiver
