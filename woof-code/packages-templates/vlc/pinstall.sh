#!/bin/sh

if [ ! "`pwd`" = "/" ];then

 echo "Configuring VLC ..."

  echo '#!/bin/sh' > ./usr/local/bin/defaultmediaplayer
  echo 'exec vlc "$@"' >> ./usr/local/bin/defaultmediaplayer
  chmod 755 ./usr/local/bin/defaultmediaplayer

fi
