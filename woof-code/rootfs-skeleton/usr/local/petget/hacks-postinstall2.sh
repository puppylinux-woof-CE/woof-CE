#!/bin/sh
#This script inspects the package's installed files and perform some action

PKGFILES="$1"

#pm-utils hack
if [ "$(cat "$PKGFILES" | grep "bin/pm-suspend-hybrid")" != "" ]; then
 for pmsh in $(cat "$PKGFILES" | grep "bin/pm-suspend-hybrid")
 do
 rm -f $pmsh
echo "#!/bin/sh
 exec pm-suspend
" > $pmsh
  chmod +x $pmsh
 done
fi

if [ "$(cat "$PKGFILES" | grep "bin/pm-hibernate")" != "" ]; then
 for pmhib in $(cat "$PKGFILES" | grep "bin/pm-hibernate")
 do
 rm -f $pmhib
echo "#!/bin/sh
 exec pm-suspend
" > $pmhib
  chmod +x $pmhib
 done
fi

#glibc hacks to prevent accidental deletion of essential runtime file
if [ "$(echo "$PKGFILES" | grep "glibc")" != "" ]; then
	if [ "$(cat "$PKGFILES" | grep "/libc.so." | grep -E "/lib")" != "" ]; then
  cat "$PKGFILES" | grep "/lib" | grep -E "\.so*" > /var/packages/builtin_files/glibc-so-libs
 fi
fi



