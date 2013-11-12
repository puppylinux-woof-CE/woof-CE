#!/bin/sh

if [ ! "`pwd`" = "/" ];then
 
 echo "Configuring Chromium web browser..."

 echo '#!/bin/sh' > ./usr/local/bin/defaultbrowser
 echo 'exec chromium-browser "$@"' >> ./usr/local/bin/defaultbrowser
 chmod 755 ./usr/local/bin/defaultbrowser
 
 #if nothing suitable installed, do this...
 #note, helpsurfer not suitable, can't display my doc/index.html 
 HTMLVIEWERFLAG='no'
 [ "`find ./bin ./usr/bin -maxdepth 1 -type f -name netsurf`" != "" ] && HTMLVIEWERFLAG='yes'
 if [ "$HTMLVIEWERFLAG" = "no" ];then
  echo '#!/bin/sh' > ./usr/local/bin/defaulthtmlviewer
  echo 'exec chromium-browser "$@"' >> ./usr/local/bin/defaulthtmlviewer
  chmod 755 ./usr/local/bin/defaulthtmlviewer
 fi

fi

#120621 Debian Squeeze: chromium is displaying in both the Network and Internet menu categories...
#note: this should really be fixed in the woof script 2createpackages.
if [ -f ./usr/share/applications/chromium-browser.desktop ];then
 cbPTN="s%^Categories=.*%Categories=WebBrowser%"
 sed -i -e "$cbPTN" ./usr/share/applications/chromium-browser.desktop
fi
