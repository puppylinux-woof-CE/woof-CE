echo '#!/bin/sh
exec geany "$@"' > usr/local/bin/defaulttexteditor
chmod 755 usr/local/bin/defaulttexteditor

echo '#!/bin/sh
exec geany "$@"' > usr/local/bin/defaulthtmleditor
chmod 755 usr/local/bin/defaulthtmleditor
