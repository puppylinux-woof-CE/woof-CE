echo '#!/bin/sh
exec claws-mail "$@"' > usr/local/bin/defaultemail
chmod 755 usr/local/bin/defaultemail
