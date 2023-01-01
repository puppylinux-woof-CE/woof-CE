#!/bin/sh
fw() {
	if [ `iptables -L -n |wc -l` -gt 10 ]; then
	  OPT=stop
	  BLURB=Off
	else
	  OPT=start
	  BLURB=On
	fi
	
	cat <<EOF
menu("fw_opts") {
  item("Turn Firewall $BLURB", Exec "/etc/init.d/rc.firewall $OPT");
}
EOF
}

net() {
	if check_internet ; then
		CON=disconnect
		DO="Disconnect from"
	else
		CON=connect
		DO="Connect to"
	fi
	cat <<EOF
menu("net_opts") {
	item("$DO the internet", Exec "/usr/local/apps/Connect/AppRun --${CON}");
	item("Network status information", Exec "ipinfo");
}
EOF
}

case $1 in
	f)fw;;
	n)net;;
esac
