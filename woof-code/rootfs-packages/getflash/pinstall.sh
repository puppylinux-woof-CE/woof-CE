#!/bin/sh
# just use relpath


PREFS="root/.getflash/getflash-prefs"
if [ ! -f $PREFS ]; then
echo '## getflash user preferences' >> $PREFS
echo '## AUTOUPDATECHECK: true = check for updates at startup | false = do not check for updates at startup' >> $PREFS
echo 'AUTOUPDATECHECK="false"' >> $PREFS
echo '## AUTOUPDATESILENTINSTALL: true = silent install | false = verbose install (user need to confirm installation of the plugin)' >> $PREFS
echo 'AUTOUPDATESILENTINSTALL="false"' >> $PREFS
echo '## AUTOUPDATESTARTUPDELAY: delay (in seconds) before startup (/root/Startup/getflash_auto) = to wait internet connection' >> $PREFS
echo 'AUTOUPDATESTARTUPDELAY="100"' >> $PREFS
fi 
