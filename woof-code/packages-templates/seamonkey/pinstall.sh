#!/bin/sh
#post-install script for Mozilla.
#assume current directory is rootfs-complete, which has the final filesystem.

if [ ! "`pwd`" = "/" ];then

 echo "Configuring Mozilla SeaMonkey browser..."

  echo '#!/bin/sh' > ./usr/local/bin/defaultbrowser
  echo 'exec mozstart "$@"' >> ./usr/local/bin/defaultbrowser

  if [ ! -f usr/local/bin/gtkmoz ];then
   ln -s mozstart usr/local/bin/gtkmoz
  fi

  echo '#!/bin/sh' > ./usr/local/bin/defaultemail
  echo 'exec mozmail "$@"' >> ./usr/local/bin/defaultemail

  echo '#!/bin/sh' > ./usr/local/bin/defaulthtmleditor
  echo 'exec mozedit "$@"' >> ./usr/local/bin/defaulthtmleditor

  echo '#!/bin/sh' > ./usr/local/bin/defaultcontact
  echo 'exec mozaddressbook "$@"' >> ./usr/local/bin/defaultcontact

 echo "Note that mozilla and netscape all point to mozstart in /usr/local/bin"
 echo "...ok, setup for Mozilla (Seamonkey)."
 echo -n "seamonkey" > /tmp/rightbrwsr.txt

fi
