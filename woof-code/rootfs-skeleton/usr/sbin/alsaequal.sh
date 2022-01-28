#!/bin/ash
# jamesbond 2011, 2014
# updated Fatdog 700 - simplify, remove control, leave with "mixer" functionality only
# 131130 L18L internationalisation

# std localisation stanza
export TEXTDOMAIN=fatdog
. gettext.sh
# performance tweak - use "C" if there is no localisation
! [ -e $TEXTDOMAINDIR/${LANG%.*}/LC_MESSAGES/$TEXTDOMAIN.mo ] &&
! [ -e $TEXTDOMAINDIR/${LANG%_*}/LC_MESSAGES/$TEXTDOMAIN.mo ] && LANG=C

### configuration
APPNAME="$(gettext 'Alsa Equaliser')"
SPOT_HOME=$(awk -F: '$1=="spot" {print $6}' /etc/passwd)
ASOUNDRC=${ASOUNDRC:-/etc/asound.conf}	# This is for Puppy

if grep -q ctl.equal $ASOUNDRC 2> /dev/null; then
	alsamixer -D equal
else
	Xdialog --title "$APPNAME" --infobox "$(eval_gettext '$APPNAME turned off, it must be turned on for this to work.')" 0 0 10000
fi

