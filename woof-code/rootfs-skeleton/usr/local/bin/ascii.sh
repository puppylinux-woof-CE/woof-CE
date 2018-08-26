#!/bin/bash
#
# Example-T2 from http://tldp.org/LDP/abs/html/asciitable.html
# modified
#

# Script author: Joseph Steinhauser
# Lightly edited by ABS Guide author, but not commented.
# Used in ABS Guide with permission.

#-------------------------------------------------------------------------
#-- File:  ascii.sh    Print ASCII chart, base 10/16         (JETS-2012)
#-------------------------------------------------------------------------
#-- Usage: ascii [oct|8]
#--
#-- This script prints out a summary of ASCII char codes from Zero to 127.
#-- Numeric values may be printed in Base10, Octal, or Hex.
#--
#-- Format Based on: /usr/share/lib/pub/ascii with base-10 as default.
#-- For more detail, man ascii . . .
#-------------------------------------------------------------------------

[ -n "$BASH_VERSION" ] && shopt -s extglob

if [ ! "$ASCII_GUI" ] ; then
	if [ $DISPLAY ] ; then
		export ASCII_GUI=1
		export COLUMNS=4
		exec gtk_text_info $0 $@
	fi
fi

[ -z $COLUMNS ] && COLUMNS=6

case "$1" in
	oct|[Oo]?([Cc][Tt])|8) Obase=Octal;  Numy=3o;;
esac

printf "          ## ASCII Chart ##  $Obase\n\n"
FM0="|%02X"
FM1="%0${Numy:-3d}"
LD=-1

AB="nul soh stx etx eot enq ack bel bs tab nl vt np cr so si dle"
AD="dc1 dc2 dc3 dc4 nak syn etb can em sub esc fs gs rs us sp"

for TOK in $AB $AD; do
	ABR[$((LD+=1))]=$TOK
done
ABR[127]=del

IDX=0
while [ $IDX -le 127 ] && CHR="${ABR[$IDX]}"
do
	if ((${#CHR})) ; then
		FM2='%-3s'
	else
		FM2=`printf '\\\\%o  ' $IDX`
	fi
	printf "$FM0 $FM1 $FM2" "$IDX" "$IDX" $CHR
	(( (IDX+=1)%${COLUMNS})) || echo '|'
done

exit $?

### END ###