#!/bin/sh

########################################################################
#
#  Convert an rtf document to PostScript format using 'Ted'.
#
#  Usage	rtf2ps.sh --paper paper something.rtf something.ps
#  Or		rtf2ps.sh something.rtf something.ps
#
#  Valid values for paper are a4, a5, a6, letter, legal and executive
#
#  This is an example. Refer to http://www.nllgg.nl/Ted/index.html for the
#  'Ted' documentation.
#
#  If you want 'Ted' to use X11 configurable resources, use
#  Ted ++printToFilePaper ... In conjuction with X11 resources, the 
#  standard X11 command line arguments to set resources can be practical. E.G:
#  Ted -xrm Ted.usePostScriptFilters:1 -xrm Ted.usePostScriptIndexedImages:1 
#	++printToFilePaper .....
#
########################################################################

PAPER=

case $# in
    2)
	;;
    4)
	case $1 in
	    --paper)
		;;
	    *)
		echo $0: '$1='$1 'Expected --paper'
		exit 1
		;;
	esac

	case $2 in
	    a4|a5|a6|letter|legal|executive)
		PAPER=$2
		;;
	    *)
		echo $0: '$2='$2 'Expected a4|a5|a6|letter|legal|executive'
		exit 1
		;;
	esac
	shift; shift;
	;;
    *)
	echo $0: '$#='$#
	exit 1
	;;
esac

case $PAPER in
    ?*)
	Ted --printToFilePaper $1 $2 $PAPER
	;;
    *)
	Ted --printToFile $1 $2
	;;
esac

