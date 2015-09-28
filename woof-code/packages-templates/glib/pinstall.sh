#!/bin/sh

echo "Post-install script for glib..."

for i in ./usr/lib/glib-2.0/*; do
	[ ! -f "$i" ] && continue
	name="`basename "$i"`"
	[ ! -e "./usr/bin/$name" ] && ln -s "/usr/lib/glib-2.0/$name" ./usr/bin/
done

#also need this for slackware 13.1...
rm -f ./etc/profile.d/*.csh* 2>/dev/null
rm -f ./etc/profile.d/.wh.* 2>/dev/null
