#!/bin/sh
#Barry Kauler, Feb. 2012. GPL3 (/usr/share/doc/legal)
#this is the post-install script for a langpack PET created by /usr/sbin/momanager.
#MoManager will replace the strings TARGETLANG and POSTINSTALLMSG.
#120315 maybe have hunspell dictionaries in langpack.
#120830 improved symlinks to hunspell dictionaries.
#120924 DejaVu font no good for non-Latin languages. 120925 add korean.
#120926 translate Comment field in .desktop file. note: applications.in now handled in /usr/local/petget/installpkg.sh.
#120927 L18L requested if there is already a translation in .desktop, remove it, replace with one from langpack.
#121011 L18L requested call to extra hacks script.
#130503 L18L: merge AppInfo.xml.in with AppInfo.xml
#130503 L18L: langpack may be different from current LANG setting. fixed.

echo "Post install script for TARGETLANG language pack"

 LANG="`grep '^LANG=' /etc/profile | cut -f 2 -d '=' | cut -f 1 -d ' '`"
 export LANG
LANG1="`cat pet.specs | cut -d'-' -f1 | cut -d'_' -f2-`" #130503 L18L: langpack may be different from current LANG setting.

if [ -d usr/share/applications.in ];then #refer: /usr/sbin/momanager
 for ADESKTOPFILE in `find usr/share/applications.in -mindepth 1 -maxdepth 1 -type f -name '*.desktop' | tr '\n' ' '`
 do
  ABASEDESKTOP="`basename $ADESKTOPFILE`"
  ADIRDESKTOP=''
  [ -f usr/share/applications/${ABASEDESKTOP} ] && ADIRDESKTOP='usr/share/applications'
  [ ! "$ADIRDESKTOP" ] && [ -f usr/local/share/applications/${ABASEDESKTOP} ] && ADIRDESKTOP='usr/local/share/applications'
  if [ "$ADIRDESKTOP" ];then
   if [ "`grep '^Name\[TARGETLANG\]' usr/share/applications.in/${ABASEDESKTOP}`" != "" ];then
    if [ "`grep '^Name\[TARGETLANG\]' ${ADIRDESKTOP}/${ABASEDESKTOP}`" != "" ];then
     #120927 L18L requested if there is already a translation, remove it, replace with one from langpack.
     grep -v '^Name\[TARGETLANG\]' ${ADIRDESKTOP}/${ABASEDESKTOP} > /tmp/momanager-pinstall-sh-desktop
     mv -f /tmp/momanager-pinstall-sh-desktop ${ADIRDESKTOP}/${ABASEDESKTOP}
    fi
    #aaargh, these accursed back-slashes! ....
    INSERTALINE="`grep '^Name\[TARGETLANG\]' usr/share/applications.in/${ABASEDESKTOP} | sed -e 's%\[%\\\\[%' -e 's%\]%\\\\]%'`"
    sed -i -e "s%^Name=%${INSERTALINE}\\nName=%" ${ADIRDESKTOP}/${ABASEDESKTOP}
   fi
   #120926 do same for Comment field...
   if [ "`grep '^Comment\[TARGETLANG\]' usr/share/applications.in/${ABASEDESKTOP}`" != "" ];then
    if [ "`grep '^Comment\[TARGETLANG\]' ${ADIRDESKTOP}/${ABASEDESKTOP}`" != "" ];then
     #120927 L18L requested if there is already a translation, remove it, replace with one from langpack.
     grep -v '^Comment\[TARGETLANG\]' ${ADIRDESKTOP}/${ABASEDESKTOP} > /tmp/momanager-pinstall-sh-desktop
     mv -f /tmp/momanager-pinstall-sh-desktop ${ADIRDESKTOP}/${ABASEDESKTOP}
    fi
    #aaargh, these accursed back-slashes! ....
    INSERTALINE="`grep '^Comment\[TARGETLANG\]' usr/share/applications.in/${ABASEDESKTOP} | sed -e 's%\[%\\\\[%' -e 's%\]%\\\\]%'`"
    sed -i -e "s%^Comment=%${INSERTALINE}\\nComment=%" ${ADIRDESKTOP}/${ABASEDESKTOP}
   fi
  fi
 done
fi

if [ -d usr/share/desktop-directories.in ];then
 for ADESKTOPFILE in `find usr/share/desktop-directories.in -mindepth 1 -maxdepth 1 -type f -name '*.directory' | tr '\n' ' '`
 do
  ABASEDESKTOP="`basename $ADESKTOPFILE`"
  if [ -f usr/share/desktop-directories/${ABASEDESKTOP} ];then
   if [ "`grep '^Name\[TARGETLANG\]' usr/share/desktop-directories/${ABASEDESKTOP}`" = "" ];then
    if [ "`grep '^Name\[TARGETLANG\]' usr/share/desktop-directories.in/${ABASEDESKTOP}`" != "" ];then
     #aaargh, these accursed back-slashes! ....
     INSERTALINE="`grep '^Name\[TARGETLANG\]' usr/share/desktop-directories.in/${ABASEDESKTOP} | sed -e 's%\[%\\\\[%' -e 's%\]%\\\\]%'`"
     sed -i -e "s%^Name=%${INSERTALINE}\\nName=%" usr/share/desktop-directories/${ABASEDESKTOP}
    fi
   fi
  fi
 done
 rm -r -f usr/share/desktop-directories.in
fi

#130503 L18L: merge AppInfo.xml.in with AppInfo.xml
for AFILE in `ls -1 usr/local/apps/*/AppInfo.xml.in | tr '\n' ' '`
do
 XMLFILE="`echo $AFILE|rev|cut -d'.' -f2- | rev`"
 SUMMARY="`grep \<Summary\> $AFILE`" # ex: '<Summary>Trash<Summary>'
 oldSUMMARY=`grep "\<Summary\ xml\:lang\=\"$LANG1" $XMLFILE` # ex: '<Summary xml:lang="de">Muell<Summary>'
 mySUMMARY=`grep "\<Summary\ xml\:lang\=\"${LANG1}" $AFILE` # ex: '<Summary xml:lang="de">Müll<Summary>'
 [ "$mySUMMARY" ] || continue
 sed -ie "/Summary\ xml\:lang\=\"${LANG1}/d"   $XMLFILE # delete translation
 sed -ie "s#${SUMMARY}#${SUMMARY}\n${mySUMMARY}#" $XMLFILE # insert it
 # the Labels now
 sed -ie "/Label\ xml\:lang\=\"${LANG1}/d" $XMLFILE # delete all translations of Label
 #find <Label>s and <Label xml:lang=$LANG1>
 grep '<Label>' $AFILE > /tmp/appinfoLABLE
 grep '<Label xml:lang=\"'${LANG1} $AFILE > /tmp/appinfoXMLLABLE
 N=0;
 while read LINE
 do
  N=$(($N + 1));echo $N
  LABEL="`head -n $N /tmp/appinfoLABLE | tail -n 1`" # is N th line
  sed -ie "s#${LABEL}#${LABEL}\n${LINE}#" $XMLFILE # insert translation
 done < /tmp/appinfoXMLLABLE
done
rm /tmp/appinfoLABLE /tmp/appinfoXMLLABLE
echo "...merge AppInfo.xml.in with AppInfo.xml finished"

#120830 improved...
if [ -d ./usr/share/hunspell ];then
 for ONEHUN in `find ./usr/share/hunspell -mindepth 1 -maxdepth 1 -type f -name '*.dic' -o -name '*.aff' | tr '\n' ' '`
 do
  HUNBASE="`basename $ONEHUN`"
  DICTDIRS="`find ./usr/lib -mindepth 2 -maxdepth 2 -type d -name dictionaries | tr '\n' ' '`"
  for ONEDICTDIR in $DICTDIRS
  do
   [ ! -e ${ONEDICTDIR}/${HUNBASE} ] && ln -s ../../../share/hunspell/${HUNBASE} ${ONEDICTDIR}/${HUNBASE}
  done
 done
fi

#120924 DejaVu font no good for non-Latin languages...
#see also similar code in /usr/local/petget/hacks-postinstall.sh.
LANGPACKLANG=TARGETLANG
case $LANGPACKLANG in
 zh*|ja*|ko*) #chinese, japanese, korean
  sed -i -e 's%DejaVu Sans%Sans%' ./etc/xdg/templates/_root_*
  if [ -d ./root/.jwm ];then
   sed -i -e 's%DejaVu Sans%Sans%' ./root/.jwm/themes/*-jwmrc
   sed -i -e 's%DejaVu Sans%Sans%' ./root/.jwm/jwmrc-theme
  fi
  [ -d ./etc/xdg/openbox ] && sed -i -e 's%DejaVu Sans%Sans%' ./etc/xdg/openbox/*.xml
  [ -d ./root/.config/openbox ] && sed -i -e 's%DejaVu Sans%Sans%' ./root/.config/openbox/*.xml
  GTKRCFILE="$(find ./usr/share/themes -type f -name gtkrc | tr '\n' ' ')"
  for ONEGTKRC in $GTKRCFILE
  do
   sed -i -e 's%DejaVu Sans%Sans%' $ONEGTKRC
  done
  if [ -d ./root/.mozilla ];then
   MOZFILE="$(find ./root/.mozilla -type f -name prefs.js -o -name '*.css' | tr '\n' ' ')"
   for ONEMOZ in $MOZFILE
   do
    sed -i -e 's%DejaVu Sans%Sans%' $ONEMOZ
   done
  fi
 ;;
esac

if [ "`pwd`" = "/" ];then #installing PET in a running puppy.
 if [ "$LANG1" != "en" ];then
  #need to update SSS translations...
  fixdesk
  fixmenus
  [ -r /pinstall_hacks.sh ] && . /pinstall_hacks.sh #121011 L18L
  pupdialog --background green --backtitle "Language Pack" --msgbox "POSTINSTALLMSG" 0 0 &
 fi
fi
