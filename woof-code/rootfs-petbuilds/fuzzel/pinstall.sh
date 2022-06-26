echo '#!/bin/sh
exec fuzzel --config $XDG_RUNTIME_DIR/fuzzel.ini "$@"' > usr/local/bin/defaultrun
chmod 755 usr/local/bin/defaultrun
