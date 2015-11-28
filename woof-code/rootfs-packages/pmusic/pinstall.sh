#!/bin/sh
#BK Note!!!
#In the pinstall.sh script you must not use absolute paths.
#The woof build script has "cd /usr/lib" -- building in Woof, that changes the directory to my host system, then as all the pinstall.sh scripts are concatenated to one big pinstall.sh, all following operations will take affect on the host system. Potential disaster.

#set default audioplayer for WOOF install only
if [ "`pwd`" != "/" ]; then
   echo '#!/bin/sh' > ./usr/local/bin/defaultaudioplayer
   echo 'exec pmusic "$@"' >> ./usr/local/bin/defaultaudioplayer
   chmod 755 ./usr/local/bin/defaultaudioplayer
fi 
