#!/bin/ash

if [ "$1" = "open" ] ; then
	exec defaulthtmlviewer file:///usr/share/doc/index.html
fi

###END###
