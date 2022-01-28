echo '#!/bin/sh
exec lxtask "$@"' > usr/local/bin/defaultprocessmanager
chmod 755 usr/local/bin/defaultprocessmanager
