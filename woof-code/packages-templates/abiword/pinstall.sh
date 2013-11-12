#!/bin/sh
#post-install script.

if [ "`pwd`" != "/" ];then

  echo '#!/bin/sh' > ./usr/local/bin/defaultwordprocessor
  echo 'exec abiword "$@"' >> ./usr/local/bin/defaultwordprocessor
  chmod 755 ./usr/local/bin/defaultwordprocessor

fi
