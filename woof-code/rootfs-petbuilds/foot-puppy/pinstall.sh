echo '#!/bin/sh
exec footclient "$@"' > usr/local/bin/defaultterminal
chmod 755 usr/local/bin/defaultterminal

if [ -e usr/bin/urxvt ]; then
	rm -f usr/bin/foot-urxvt
else
	ln -s foot-urxvt usr/bin/urxvt
	ln -s foot-urxvt usr/bin/rxvt
	rm -f usr/bin/xterm
	ln -s foot-urxvt usr/bin/xterm
fi
