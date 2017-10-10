#!/bin/sh
#post-install script.

if [ ! -f ./usr/bin/geany ];then
  if [ ! -f ./usr/bin/gedit  ];then
   echo '#!/bin/sh' > ./usr/local/bin/defaulttexteditor
   echo 'exec leafpad "$@"' >> ./usr/local/bin/defaulttexteditor
   chmod 755 ./usr/local/bin/defaulttexteditor
  fi
fi

echo '#!/bin/sh' > ./usr/local/bin/defaulttextviewer
echo 'exec leafpad "$@"' >> ./usr/local/bin/defaulttextviewer
chmod 755 ./usr/local/bin/defaulttextviewer
