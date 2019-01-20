#!/bin/sh

if [ -d usr/lib64/cups/backend ] ; then
	# slackware64
	cp usr/lib/cups/backend/pdf-writer usr/lib64/cups/backend/
	cp usr/lib/cups/backend/smbw usr/lib64/cups/backend/
fi

if [ -d usr/share/ghostscript ] ; then
	ghostpdf=$(find usr/share/ghostscript -name ghostpdf.ppd)
	if [ "$ghostpdf" ] ; then
		mkdir -p usr/share/cups/model
		ln -snf /${ghostpdf} usr/share/cups/model/ghostpdf.ppd
	fi
fi
