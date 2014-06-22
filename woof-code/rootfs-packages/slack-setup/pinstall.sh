#!/bin/sh
# Slackware puppy specific modifications
#

rm etc/profile.d/lang.*sh # toxic, puppy set the LANG elsewhere.

# tell ROX to use puppy's icons
rm -rf usr/libexec/ROX-Filer/ROX/MIME
ln -sf /usr/local/apps/ROX-Filer/ROX/MIME usr/libexec/ROX-Filer/ROX
