if ldd $(which gtkdialog) | grep -iq 'gtk\-3' ; then #gtk3
	GTKDIALOG_BUILD=GTK3
	GTKDIALOG_MAX_CHARS=' max-width-chars="80"'
elif ldd $(which gtkdialog) | grep -iq 'gtk\-X11\-2' ; then #gtk2
	GTKDIALOG_BUILD=GTK2
	GTKDIALOG_MAX_CHARS=''
fi
export GTKDIALOG_BUILD
export GTKDIALOG_MAX_CHARS
