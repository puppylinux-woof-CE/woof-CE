echo '#!/bin/sh
exec sylpheed "$@"' > usr/local/bin/defaultemail

chroot . /usr/sbin/setup-spot sylpheed=true
