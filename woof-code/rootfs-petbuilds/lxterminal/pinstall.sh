echo '#!/bin/sh
exec lxterminal "$@"' > usr/local/bin/defaultterminal
chmod 755 usr/local/bin/defaultterminal

if [ -e usr/bin/urxvt ]; then
	rm -f usr/bin/lxterminal-urxvt
else
	ln -s lxterminal-urxvt usr/bin/urxvt
	ln -s lxterminal-urxvt usr/bin/rxvt
	rm -f usr/bin/xterm
	ln -s lxterminal-urxvt usr/bin/xterm
fi
