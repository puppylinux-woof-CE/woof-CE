echo '#!/bin/sh
exec gnumeric "$@"' > usr/local/bin/defaultspreadsheet
chmod 755 usr/local/bin/defaultspreadsheet
