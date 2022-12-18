echo '#!/bin/sh
exec abiword "$@"' > usr/local/bin/defaultwordprocessor
chmod 755 usr/local/bin/defaultwordprocessor
