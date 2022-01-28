echo '#!/bin/sh
exec gexec "$@"' > usr/local/bin/defaultrun
chmod 755 usr/local/bin/defaultrun
