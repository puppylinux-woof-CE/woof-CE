#!/bin/sh

echo "Post-install script for glib..."

#also need this for slackware 13.1...
rm -f ./etc/profile.d/*.csh* 2>/dev/null
rm -f ./etc/profile.d/.wh.* 2>/dev/null
