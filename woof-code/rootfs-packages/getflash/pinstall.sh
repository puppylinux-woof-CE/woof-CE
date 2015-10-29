#!/bin/sh
#20151023 ASRI: create getflash-prefs if not already exist

#By BK on http://www.murga-linux.com/puppy/viewtopic.php?t=90784&start=217
# put this code (when building in woof, don't want that code to run)
#if [ "`pwd`" = "/" ];then 
#... 
#fi

if [ "`pwd`" = "/" ];then #BK

PREFS="/usr/sbin/getflash-prefs"
if [ ! -f $PREFS ]; then
echo '## getflash user preferences' >> $PREFS
echo '## AUTOUPDATECHECK: true = check for updates at startup | false = do not check for updates at startup' >> $PREFS
echo 'AUTOUPDATECHECK="true"' >> $PREFS
echo '## AUTOUPDATESILENTINSTALL: true = silent install | false = verbose install (user need to confirm installation of the plugin)' >> $PREFS
echo 'AUTOUPDATESILENTINSTALL="false"' >> $PREFS
echo '## AUTOUPDATESTARTUPDELAY: delay (in seconds) before startup (/root/Startup/getflash_auto) = to wait internet connection' >> $PREFS
echo 'AUTOUPDATESTARTUPDELAY="100"' >> $PREFS
fi 

fi #BK