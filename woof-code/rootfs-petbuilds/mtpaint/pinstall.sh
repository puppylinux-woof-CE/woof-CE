echo '#!/bin/sh
exec mtpaint "$@"' > usr/local/bin/defaultimageeditor
chmod 755 usr/local/bin/defaultimageeditor

echo '#!/bin/sh
exec mtpaint -s "$@"' > usr/local/bin/defaultscreenshot
chmod 755 usr/local/bin/defaultscreenshot
