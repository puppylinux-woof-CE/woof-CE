#!/bin/sh

if [ ! "`pwd`" = "/" ];then

 echo "Configuring MPlayer..."
 
 if [ ! -f ./usr/bin/gnome-mplayer ];then

  echo '#!/bin/sh' > ./usr/local/bin/defaultmediaplayer
  echo 'exec mplayershell "$@"' >> ./usr/local/bin/defaultmediaplayer
  chmod 755 ./usr/local/bin/defaultmediaplayer

  echo '#!/bin/sh' > ./usr/local/bin/defaultvideoplayer
  echo 'exec mplayershell "$@"' >> ./usr/local/bin/defaultvideoplayer
  chmod 755 ./usr/local/bin/defaultvideoplayer
  
# else
# 
#  #gnome-mplayer is the default media player.
#  #also, save space, get rid of the mplayer gui...
#  rm -f ./usr/share/applications/mplayer.desktop
#  rm -f ./usr/bin/gmplayer
#  rm -rf ./usr/share/mplayer/*
  
 fi

fi
