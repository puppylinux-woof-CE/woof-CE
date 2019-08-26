#!/bin/sh
#Remove dynamically created files...
if ! which pgprs &>/dev/null;then
 rm -f /etc/ppp/chatscripts/gprs-*_command
 rm -f /etc/ppp/peers/gprs-generated
 rm -f /etc/ppp/peers/gprs-auth
 rm -f /root/.config/gprs.conf
fi

if [ -f /etc/init.d/frisbee ];then #old version
 chmod a+x etc/init.d/frisbee #150228
else
 rm -fr /etc/frisbee
 rm -fr /usr/local/frisbee
fi
rm -f /etc/dhcpcd_state_notify

#Change connectwizard frisbee default to connectwizard.
grep 'frisbee' /usr/local/bin/defaultconnect \
 && echo -e "#!/bin/sh\nexec connectwizard" > /usr/local/bin/defaultconnect
