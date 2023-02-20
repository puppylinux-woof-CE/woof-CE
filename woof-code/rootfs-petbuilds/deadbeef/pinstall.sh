echo '#!/bin/sh
exec deadbeef "$@"' > usr/local/bin/defaultaudioplayer
chmod 755 usr/local/bin/defaultaudioplayer

echo '#!/bin/sh
exec deadbeef all.cda' > usr/local/bin/defaultcdplayer
chmod 755 usr/local/bin/defaultcdplayer
