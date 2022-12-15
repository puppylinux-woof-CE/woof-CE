#!/bin/sh
#241022

input="$1"
pkgdir="$2"
output="$3"
repo="index.plist"		#from 0setup

echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>' > out

while IFS= read -r line
do
  case "$line" in \#*) continue ;; esac
  vpkg=
  vpkg=`echo "$line" | cut -d \| -f 2 | grep "compat"`
  [ ! $vpkg ] && continue
  vpkg=`echo "$line" | cut -d \| -f 5`
  metadev=${pkgdir}/${vpkg}_DEV/files.plist
  [ -e ${metadev} ] && continue
  meta=${pkgdir}/${vpkg}/files.plist
  sha256=`[ -e ${meta} ] && sha256sum ${meta} | cut -d ' ' -f 1`
  vpkg="<key>${vpkg}</key>"
  begnum=`grep -n $vpkg $repo | head -1 | cut -d : -f 1`
  finnum=`tail -n +"$begnum" $repo | grep -n "<key>source-revisions" | head -1 | cut -d : -f 1`
  finnum=`expr $begnum + $finnum + 1`

  sed -n "${begnum},${finnum}p" $repo > tmpout
  sed -i '/<key>filename-sha256/i \\t\t<key>automatic-install</key>\n\t\t<true/>' tmpout
  sed -i '/<key>installed_size/i \\t\t<key>install-date</key>\n\t\t<string>2021-12-01 10:00 UTC</string>' tmpout
  [ ${sha256} ] && sed -i "/<key>pkgver/i \\\t\t<key>metafile-sha256</key>\n\t\t<string>${sha256}</string>\n\t\t<key>pkgname</key>\n\t\t<string>acl</string>" tmpout
  sed -i '/<key>run_depends/i \\t\t<key>repository</key>\n\t\t<string>https://repo-us.voidlinux.org/current</string>' tmpout
  sed -i '/<\/dict>/i \\t\t<key>state</key>\n\t\t<string>installed</string>' tmpout
    
  cat tmpout >> out

done < "$input"

echo '</dict>
</plist>' >> out
sed -i 's%shlib-requires%zzshlib-requires%g' out
mv -f out "$output"
rm tmpout
