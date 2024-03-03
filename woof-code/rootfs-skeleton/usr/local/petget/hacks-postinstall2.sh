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


if [ "$(grep "/opt" "$PKGFILES" | grep -m 1 "/QtWebEngineProcess")" != "" ]; then

 for fle in $(grep -E "\.desktop" "$PKGFILES" | tr '\n' ' ')
 do
  sed -i -e "s#^Exec=#Exec=run-as-spot\ #g" "$fle"
 done
 
fi


if [ "$(echo "$PKGFILES" | grep -E "chrome|vivaldi|opera|chromium|brave|srware|rekonq|microsoft\-edge|msdge")" != "" ]; then
 
 for fle in $(grep -E "\.desktop" "$PKGFILES" | tr '\n' ' ')
 do
  sed -i -e "s#^Exec=#Exec=run-as-spot\ #g" "$fle"
 done

elif [ "$(grep -m 1 "/chrome-sandbox" "$PKGFILES")" != "" ]; then
 
 for fle in $(grep -E "\.desktop" "$PKGFILES" | tr '\n' ' ')
 do
  sed -i -e "s#^Exec=#Exec=run-as-spot\ #g" "$fle"
 done

fi

