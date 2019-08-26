#!/bin/sh
# just use relpath

PREFS="root/.getflash/getflash-prefs"
[ "$(pwd)" = "/" -a ! -f $PREFS ] && cat > $PREFS <<-EOF
	## getflash user preferences
	
	## AUTOUPDATECHECK: true = check for updates at startup | false = do not check for updates at startup
	AUTOUPDATECHECK="false"
	
	## AUTOUPDATESILENTINSTALL: true = silent install | false = verbose install (user need to confirm installation of the plugin)
	AUTOUPDATESILENTINSTALL="false"
	
	## AUTOUPDATESTARTUPDELAY: delay (in seconds) before startup (/root/Startup/getflash_auto) = to wait internet connection
	AUTOUPDATESTARTUPDELAY="100"
	EOF

# Remove residual configuration file in old location.
rm -f usr/sbin/getflash-conf #v1.5.7
rm -f etc/getflash.conf #v1.6.x
