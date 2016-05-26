#!/bin/sh

#Remove old pgprs components...
if [ "$(pwd)" != "/" ] \
  || [ -f /lib/modules/all-firmware/pgprs.tar.gz \
       -o -d /lib/modules/all-firmware/pgprs ]; then
 rm -f etc/ppp/peers/gprs-connect-chatmm 2>/dev/null
 rm -f etc/ppp/peers/gprs-disconnect-chatmm 2>/dev/null
 rm -f etc/ppp/peers/gprsmm 2>/dev/null
 rm -f usr/share/applications/pgprs-setup.desktop 2>/dev/null
 if [ "$(pwd)" != "/" ];then
  rm -fr lib/modules/all-firmware/pgprs 2>/dev/null
  rm -f lib/modules/all-firmware/pgprs.tar.gz 2>/dev/null
 fi
fi

#Disable/remove old pgprs scripts in old location.
if [ "$(pwd)" = "/" ] \
  && [ ! -f /lib/modules/all-firmware/pgprs.tar.gz \
  -a ! -d /lib/modules/all-firmware/pgprs ]; then
 chmod -f a-x  usr/bin/pgprs-setup
 chmod -f a-x  usr/bin/pgprs-connect
else
 rm -f usr/bin/pgprs-setup
 rm -f usr/bin/pgprs-connect
 [ "$(pwd)" != "/" ] && rm -f usr/sbin/pgprs-shell
fi

#Install gprs-editable only if not already present...
if [ "$(pwd)" = "/" -a -f etc/ppp/peers/gprs-editable ];then
 rm -f etc/ppp/peers/gprs-editable.tmp
 sed -i '/gprs-editable\.tmp/d' root/.packages/pgprs-*.files
else
 mv -f etc/ppp/peers/gprs-editable.tmp etc/ppp/peers/gprs-editable
 sed -i '/gprs-editable\.tmp/ s/\.tmp//' root/.packages/pgprs-*.files
fi

#Remove old state gprs.conf, to generate new one.
rm -f etc/gprs.conf
rm -f root/.config/gprs.conf

#Remove replaced options file, if not used by frisbee.
[ -f usr/sbin/frisbee ] && rm -f etc/ppp/options.gprs

#Change connectwizard pgprs default to connectwizard.
if [ "$(pwd)" = "/" ];then
 grep 'pgprs' usr/local/bin/defaultconnect \
  && echo -e "#!/bin/sh\nexec connectwizard" > usr/local/bin/defaultconnect
fi

#For very old puppies, revert the menu category.
! grep -qs 'X-Network-phone' etc/xdg/menus/puppy-network.menu \
 && grep -qs '>Dialup<' etc/xdg/menus/puppy-network.menu \
 && sed -i 's/X-Network-phone/Dialup/' usr/share/applications/pgprs-connect.desktop
