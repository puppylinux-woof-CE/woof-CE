#!/bin/sh

if [ ! "`pwd`" = "/" ];then

  echo '#!/bin/sh' > ./usr/local/bin/defaulthtmleditor
  echo 'exec kompozer "$@"' >> ./usr/local/bin/defaulthtmleditor
  chmod 755 ./usr/local/bin/defaulthtmleditor

fi
