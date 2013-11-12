#!/bin/sh

MSGDEPS="the 'dotpuphandler' PET package."
[ "`which puppybasic`" = "" ] && MSGDEPS="the 'dotpuphandler' and 'puppybasic' PET packages."

xmessage "DotPup packages (files with .pup extension) are an older
package system superceded by PET packages. If you want to
install a DotPup package, you must first run the PETget
package manager (see install icon on desktop) and install
${MSGDEPS}"
