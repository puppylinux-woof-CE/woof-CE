#!/bin/sh
#post-install script.

if [ "`pwd`" != "/" ];then

 echo '#!/bin/sh' > ./usr/local/bin/defaultbrowser
 echo 'exec midori "$@"' >> ./usr/local/bin/defaultbrowser
 chmod 755 ./usr/local/bin/defaultbrowser

 echo "...ok, setup for Midori."
 echo -n "midori" > /tmp/rightbrwsr.txt

fi
