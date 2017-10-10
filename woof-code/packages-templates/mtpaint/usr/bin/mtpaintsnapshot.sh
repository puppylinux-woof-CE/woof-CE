#!/bin/sh
#110116 change to yaf-splash.
#110312 rodin.s: adding gettext

export TEXTDOMAIN=mtpaintsnapshot #usr_sbin
export OUTPUT_CHARSET=UTF-8

yaf-splash -placement center -bg '#ff00ff' -timeout 10 -close box -text "$(gettext 'mtPaint screen snapshot utility

There will now be a pause of 13 seconds to allow you to adjust windows as you wish, then a snapshot will be taken of entire screen.

Note, you can also take a snapshot of the main menu. Close this window, open the main menu to the desired layout, then wait until the 13 seconds has expired.')" &

sleep 13
exec mtpaint -s
