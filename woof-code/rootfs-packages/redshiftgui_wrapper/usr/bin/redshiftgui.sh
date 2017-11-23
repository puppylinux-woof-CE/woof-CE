#!/bin/sh
# redshiftgui.sh - Wrapper for RedshiftGUI (redshiftgui)
# Kills any running redshiftGUI.
# Ensures correct "map" separators (',', not |).
# Ensures normal invocation not minimized (in case set during  a save).

# To disable automatic starting, remove execute permissions of
# /root/Startup/redshiftgui_tray.

if which redshiftgui &>/dev/null; then
	if [ "$1" = '--help' -o "$1" = '-h' ];then
		export TEXTDOMAIN=redshiftgui.sh
		export OUTPUT_CHARSET=UTF-8
		echo "$(gettext 'To activate automatic startup, specify a location in redshiftGUI.')"
		echo "$(gettext 'To de-activate automatic startup, set location to 0, 0 in redshiftGUI.')"
		echo #then append redshiftgui help
	else
		[ "$(pidof redshiftgui)" ] && kill $(pidof redshiftgui)
		if grep -qsE '^min$|\|' ~/.redshiftgrc; then
			if [ -x /root/Startup/redshiftgui_tray ];then
				sed -i -e '/^min/d' -e '/map=/ s/|/,/g' ~/.redshiftgrc
			else
				grep -q '|' ~/.redshiftgrc \
				  && sed -i '/map=/ s/|/,/g' ~/.redshiftgrc
			fi
		fi
	fi
	exec redshiftgui "$@"
fi
