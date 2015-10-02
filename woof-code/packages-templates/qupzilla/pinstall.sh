#!/bin/sh

if [ ! "`pwd`" = "/" ];then

 echo "Configuring QupZilla browser..."

  echo '#!/bin/sh' > ./usr/local/bin/defaultbrowser
  echo 'exec qupzilla "$@"' >> ./usr/local/bin/defaultbrowser
  chmod 755 ./usr/local/bin/defaultbrowser

fi
