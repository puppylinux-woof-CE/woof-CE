#!/bin/sh

#Remove dynamically created files...
if ! which frisbee &>/dev/null;then
 rm -f /etc/ppp/chatscripts/gprs-*_command
 rm -f /etc/ppp/peers/gprs-generated 2>/dev/null
 rm -f /etc/ppp/peers/gprs-auth 2>/dev/null
 rm -f /root/.config/gprs.conf
fi
rm -fr /usr/local/pgprs

#Restore pgprs scripts in old location, when no firmware for restoration.
chmod -f a+x  /usr/bin/pgprs-setup
chmod -f a+x  /usr/bin/pgprs-connect

#Change connectwizard pgprs default to connectwizard.
grep 'pgprs' /usr/local/bin/defaultconnect \
 && echo -e "#!/bin/sh\nexec connectwizard" > /usr/local/bin/defaultconnect
