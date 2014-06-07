#!/bin/sh
#post-install script.

#unleashed: current directory is rootfs-complete, which has the final filesystem.
#petget: current directory is /.

#RUNNINGPS="`ps`"
#if [ "`echo "$RUNNINGPS" | grep "petget"`" = "" ];then
if [ ! "`pwd`" = "/" ];then

# [ ! -f ./usr/local/bin/leafpad ] && ln -s geanyshell ./usr/local/bin/leafpad
# [ ! -f ./usr/local/bin/beaver ] && ln -s geanyshell ./usr/local/bin/beaver


 echo '#!/bin/sh' > ./usr/local/bin/defaulttexteditor
 echo 'exec geany "$@"' >> ./usr/local/bin/defaulttexteditor

fi
