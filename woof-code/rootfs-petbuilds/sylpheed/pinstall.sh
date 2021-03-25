echo '#!/bin/sh
exec sylpheed "$@"' > usr/local/bin/defaultemail
chmod 755 usr/local/bin/defaultemail
