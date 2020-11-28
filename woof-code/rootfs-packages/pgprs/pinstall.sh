#!/bin/sh

#Create link to window icon, replacing placeholder.
ln -snf puppy/wireless.svg usr/share/pixmaps/pgprs.svg

if [ "$(pwd)" = "/" ];then

 if [ -f /lib/modules/all-firmware/pgprs.tar.gz \
   -o -d /lib/modules/all-firmware/pgprs ]; then
  #Remove old pgprs components...
  rm -f etc/ppp/peers/gprs-connect-chatmm 2>/dev/null
  rm -f etc/ppp/peers/gprs-disconnect-chatmm 2>/dev/null
  rm -f etc/ppp/peers/gprsmm 2>/dev/null
  rm -f usr/share/applications/pgprs-setup.desktop 2>/dev/null
 else
  #Disable/remove old pgprs scripts in old location.
  chmod -f a-x  usr/bin/pgprs-setup
  chmod -f a-x  usr/bin/pgprs-connect
 fi

 #Remove old gprs.conf, to use new one. 200607
 rm -f etc/ppp/gprs.conf

 #Remove old state gprs.conf, to generate new one.
 rm -f root/.config/gprs.conf

 #Remove replaced options file, if not used by frisbee.
 [ -f usr/local/bin/frisbee ] && rm -f etc/ppp/options.gprs

 #Change connectwizard pgprs default to connectwizard.
 grep 'pgprs' usr/local/bin/defaultconnect \
  && echo -e "#!/bin/sh\nexec connectwizard" > usr/local/bin/defaultconnect

 #For very old puppies, revert the menu category.
 ! grep -qs 'X-Network-phone' etc/xdg/menus/puppy-network.menu \
  && grep -qs '>Dialup<' etc/xdg/menus/puppy-network.menu \
  && sed -i 's/X-Network-phone/Dialup/' usr/share/applications/pgprs-connect.desktop

 #Change link to appropriate window icon.
 rm -f usr/local/lib/X11/mini-icons/pgprs.png #precaution
 if [ ! -f usr/share/pixmaps/puppy/wireless.svg ];then
  rm -f usr/share/pixmaps/pgprs.svg
  ln -snf /usr/local/lib/X11/mini-icons/Pwireless.png usr/share/pixmaps/pgprs.png
  sed -i '/pgprs\.svg/ s/svg/png/' root/.packages/pgprs-*.files
  sed -i '/pgprs\.svg/ s/svg/png/' usr/share/applications/pgprs-connect.desktop
 fi
fi

#v3.0 Replace placeholder with /usr/sbin/ link for moved pgprs script.
ln -snf /usr/local/pgprs/pgprs usr/sbin/
