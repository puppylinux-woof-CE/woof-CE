#!/bin/sh
if [ "`pwd`" != "/" ];then
echo '#!/bin/sh
exec xchat' > ./usr/local/bin/defaultchat
chmod 755 ./usr/local/bin/defaultchat
echo "setting xchat as default chat"
 else
echo '#!/bin/sh
exec xchat' > /usr/local/bin/defaultchat
chmod 755 /usr/local/bin/defaultchat
fi
