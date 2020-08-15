#!/bin/sh

#Note regarding adaptation for DebianDog distros:.
# - Edit /etc/frsibee/frisbee.conf: Change 'editor=' to specify correct editor
# - Move /usr/local/frisbee/func to /usr/lib/frisbee/.
# - Remove /usr/lib/dhcpcd-hooks/99-frisbee_tray and its link in
#   /usr/libexec/dhcpcd-hooks, from DebianDogs.

if [ "$(pwd)" = "/" ];then

 export TEXTDOMAIN=frisbee
 export OUTPUT_CHARSET=UTF-8

 #Clear all flags...
 rm -f etc/frisbee/.* 2>/dev/null #residue

 #Remove residue from prior frisbee versions...
 rm -f usr/local/frisbee/hook_notify
 rm -rf etc/frisbee/iface 2>/dev/null
 rm -f root/Startup/network_tray_modeset
 rm -f etc/dhcpcd_dropwait_secs
 rm -f etc/frisbee/interfaces

 #Remove residue from prior frisbee versions...
 if [ -d lib/dhcpcd/dhcpcd-hooks ];then
  rm -f lib/dhcpcd/dhcpcd-hooks/99-frisbee
  rm -f lib/dhcpcd/dhcpcd-hooks/99-down
  rm -f lib/dhcpcd/dhcpcd-hooks/99-ifup
  rm -f lib/dhcpcd/dhcpcd-hooks/99-release
  rm -f lib/dhcpcd/dhcpcd-hooks/99-timeout
  rm -f lib/dhcpcd/dhcpcd-hooks/99-up
 fi
 if [ ! -h usr/libexec/dhcpcd-hooks -a -d usr/libexec/dhcpcd-hooks ];then
  rm -f usr/libexec/dhcpcd-hooks/99-frisbee
  rm -f usr/libexec/dhcpcd-hooks/99-down
  rm -f usr/libexec/dhcpcd-hooks/99-ifup
  rm -f usr/libexec/dhcpcd-hooks/99-release
  rm -f usr/libexec/dhcpcd-hooks/99-timeout
  rm -f usr/libexec/dhcpcd-hooks/99-up
 fi
 if [ -d usr/lib/dhcpcd/dhcpcd-hooks ];then
  rm -f usr/lib/dhcpcd/dhcpcd-hooks/99-frisbee
  rm -f usr/lib/dhcpcd/dhcpcd-hooks/99-down
  rm -f usr/lib/dhcpcd/dhcpcd-hooks/99-ifup
  rm -f usr/lib/dhcpcd/dhcpcd-hooks/99-release
  rm -f usr/lib/dhcpcd/dhcpcd-hooks/99-timeout
  rm -f usr/lib/dhcpcd/dhcpcd-hooks/99-up
 fi

 #140526 Remove files and menu entries from Frisbee betas.
 rm -f usr/sbin/install-frisbee
 rm -f usr/share/applications/install-frisbee.desktop
 rm -fr usr/share/frisbee #150604

 #140526 Remove files and placeholders for renamed and moved internal scripts.
 rm -f usr/local/bin/fgprs_*connect

 #150301 Remove possible residue from dhcpcd.conf...
 if grep -sq 'nohook 10-wpa_supplicant' etc/frisbee/dhcpcd.conf;then
  sed -i '/nohook 10-wpa_supplicant/d' etc/frisbee/dhcpcd.conf
 fi

 #140818 150228 Disable old frisbee initialization script file but add to files list, or remove it.
 if [ -f etc/init.d/frisbee ];then
  chmod a-x etc/init.d/frisbee #150301
  (
   sleep 3
   [ "$(ls root/.packages/frisbee-1.*.files 2>/dev/null)" ] \
    && sed -i 's%/etc/init.d/frisbee.sh%/etc/init.d/frisbee\n&%' root/.packages/frisbee-1.*.files
  ) &
 fi

 ###End of residue removal section.


 #160610 Add frisbee menu item if connectwizard not present (e.g., *dogs).
 if [ ! -x usr/sbin/connectwizard ];then
  sed -i '/^NoDisplay=/ s/=.*/=false/' \
   usr/share/applications/frisbee.desktop
 fi

 # Allow installer to make frisbee the default network manager.
 if Xdialog  --title "Frisbee" --default-no --timeout 60 --ok-label "Yes, set as default" --cancel-label "No" --left --yesno "$(gettext "Frisbee is installed as one of the Connect Wizard network manager options.")\n\n$(gettext "Do you want frisbee to be the default network manager at the next boot-up or\nat the initial boot of a distro package?")" 0 0;then
  echo -e '#!/bin/sh\nexec frisbee' > usr/local/bin/defaultconnect
  sed -i -e '/^frisbee_mode=/ s/=.*/=1/' \
  -e '/^wireless_enabled=/ s/=.*/=1/' \
  -e '/^wireless_autostart=/ s/=.*/=1/' \
  -e '/^announce_state_changes=/ s/=.*/=1/' \
  etc/frisbee/frisbee.conf
  [ -f etc/dhcpcd_state_notify ] || touch etc/dhcpcd_state_notify
 else
  rm -f etc/dhcpcd_state_notify
 fi

 #160213 remove files from old locations - for builds, assume updated connectwizard_2nd is present....
 rm -f usr/local/bin/frisbee_mode_disable
 rm -f usr/local/frisbee/connect
 rm -f usr/local/frisbee/disconnect
 rm -f usr/local/bin/frisbee_cli
 if ! grep -qE 'frisbee --|frisbee_cli --' usr/local/apps/Connect/AppRun;then
  ln -snf frisbee usr/local/bin/frisbee_mode_disable
  ln -snf ../bin/frisbee usr/local/frisbee/connect
  ln -snf ../bin/frisbee usr/local/frisbee/disconnect
  [ "$(ls root/.packages/frisbee-1.*.files 2>/dev/null)" ] \
   && sed -i -e 's%/usr/local/bin/frisbee$%&\n/usr/local/bin/frisbee_mode_disable%' \
   -e 's%/usr/local/frisbee/frisbee-gprs-connect$%/usr/local/frisbee/connect\n/usr/local/frisbee/disconnect\n&%' \
   root/.packages/frisbee-1.*.files
 elif grep -q 'frisbee_cli --' usr/local/apps/Connect/AppRun;then
  ln -snf frisbee usr/local/bin/frisbee_cli
  [ "$(ls root/.packages/frisbee-1.*.files 2>/dev/null)" ] \
   && sed -i -e 's%/usr/local/bin/frisbee$%&\n/usr/local/bin/frisbee_cli%' \
   root/.packages/frisbee-1.*.files
 fi

 #Remove old gprs.conf, to generate new one.
 rm -f etc/gprs.conf
 rm -f root/.config/gprs.conf

 #Remove replaced options file, if not used by pgprs.
 [ -f usr/sbin/pgprs ] && rm -f etc/ppp/options.gprs
fi

#Replace placeholder with /usr/local/bin link to moved script.
ln -snf /usr/local/frisbee/frisbee usr/local/bin/
