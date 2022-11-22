echo '#!/bin/sh
exec palemoon "$@"' > usr/local/bin/defaultbrowser
chmod 755 usr/local/bin/defaultbrowser
