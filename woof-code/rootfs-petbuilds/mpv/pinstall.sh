echo '#!/bin/ash
[ $# -eq 0 ] && exec mpv --player-operation-mode=pseudo-gui
exec mpv "$@"' > usr/local/bin/defaultmediaplayer
chmod 755 usr/local/bin/defaultmediaplayer
