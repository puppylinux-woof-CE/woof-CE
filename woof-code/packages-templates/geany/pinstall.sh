#!/bin/sh
#post-install script.

if [ ! "`pwd`" = "/" ];then

 echo '#!/bin/sh' > ./usr/local/bin/defaulttexteditor
 echo 'exec geany "$@"' >> ./usr/local/bin/defaulttexteditor

fi
