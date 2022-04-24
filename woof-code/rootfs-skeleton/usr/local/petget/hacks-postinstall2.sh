#!/bin/sh
#This script inspects the package's installed files and perform some action

PKGFILES="$1"

#pm-utils hack
if [ "$(grep "bin/pm-suspend-hybrid" "$PKGFILES")" != "" ]; then
 for pmsh in $(grep "bin/pm-suspend-hybrid" "$PKGFILES")
 do
 rm -f $pmsh
echo "#!/bin/sh
 exec pm-suspend
" > $pmsh
  chmod +x $pmsh
 done
fi

if [ "$(grep "bin/pm-hibernate" "$PKGFILES")" != "" ]; then
 for pmhib in $(grep "bin/pm-hibernate" "$PKGFILES")
 do
 rm -f $pmhib
echo "#!/bin/sh
 exec pm-suspend
" > $pmhib
  chmod +x $pmhib
 done
fi
