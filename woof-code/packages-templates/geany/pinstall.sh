#!/bin/sh
#post-install script.

#unleashed: current directory is rootfs-complete, which has the final filesystem.
#petget: current directory is /.

if [ ! "`pwd`" = "/" ];then

 echo '#!/bin/sh' > ./usr/local/bin/defaulttexteditor
 echo 'exec geany "$@"' >> ./usr/local/bin/defaulttexteditor

fi
