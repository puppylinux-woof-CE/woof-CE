#!/bin/sh
#post-install script for Mozilla.
#assume current directory is rootfs-complete, which has the final filesystem.

#RUNNINGPS="`ps`"
#if [ "`echo "$RUNNINGPS" | grep "petget"`" = "" ];then
if [ ! "`pwd`" = "/" ];then

 echo "Configuring Mozilla SeaMonkey browser..."

  echo '#!/bin/sh' > ./usr/local/bin/defaultbrowser
  echo 'exec mozstart "$@"' >> ./usr/local/bin/defaultbrowser

  #091118 sm2 cannot have gtkmoz or puppybrowser...
  if [ ! -f usr/local/bin/gtkmoz ];then
   ln -s mozstart usr/local/bin/gtkmoz
  fi

  #if [ ! -f ./usr/local/bin/sylpheed ];then
   echo '#!/bin/sh' > ./usr/local/bin/defaultemail
   echo 'exec mozmail "$@"' >> ./usr/local/bin/defaultemail
  #fi

  echo '#!/bin/sh' > ./usr/local/bin/defaulthtmleditor
  echo 'exec mozedit "$@"' >> ./usr/local/bin/defaulthtmleditor

  #echo 'exec mozcalendar $@' > ./usr/local/bin/defaultcalendar

  #if [ ! -f ./usr/local/bin/gaby ];then
   echo '#!/bin/sh' > ./usr/local/bin/defaultcontact
   echo 'exec mozaddressbook "$@"' >> ./usr/local/bin/defaultcontact
  #fi

 echo "Note that mozilla and netscape all point to mozstart in /usr/local/bin"
 echo "...ok, setup for Mozilla (Seamonkey)."
 echo -n "seamonkey" > /tmp/rightbrwsr.txt

  

fi
