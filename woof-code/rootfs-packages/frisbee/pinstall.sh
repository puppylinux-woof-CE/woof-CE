#!/bin/sh

#Note regarding adaptation for DebianDog distros:.
# - Edit /etc/frsibee/frisbee.conf: Change 'editor=' to specify correct editor
# - Move /usr/local/frisbee/func to /usr/lib/frisbee/.
# - Remove /usr/lib/dhcpcd-hooks/99-frisbee_tray and its link in
#   /usr/libexec/dhcpcd-hooks, from DebianDogs.

export TEXTDOMAIN=frisbee
export OUTPUT_CHARSET=UTF-8

#Clear all flags...
if [ "$(pwd)" = "/" ];then
 rm -f etc/frisbee/.* 2>/dev/null #residue
fi

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

#140526 Add link to frisbee icon.
[ -h var/local/icons/frisbee.png ] \
 || ln -snf /usr/share/pixmaps/frisbee.png var/local/icons/frisbee.png

#140526 Remove frisbee menu item if connectwizard present.
[ "$(which connectwizard)" ] \
 && sed -i '/^NoDisplay=/ s/=.*/=true/' \
     usr/share/applications/frisbee.desktop

#140526 Remove files and placeholders for renamed and moved internal scripts.
rm -f usr/local/bin/fgprs_*connect

#150301 Remove possible residue from dhcpcd.conf...
if grep -sq 'nohook 10-wpa_supplicant' etc/frisbee/dhcpcd.conf;then
	sed -i '/nohook 10-wpa_supplicant/d' etc/frisbee/dhcpcd.conf
fi

#140818 150228 Disable old frisbee initialization script file but add to files list, or remove it.
if [ "$(pwd)" = "/" ];then
	if [ -f etc/init.d/frisbee ];then
	 	chmod a-x etc/init.d/frisbee #150301
		(
		sleep 3
		[ "$(ls root/.packages/frisbee-1.*.files 2>/dev/null)" ] \
		 && sed -i 's%/etc/init.d/frisbee.sh%/etc/init.d/frisbee\n&%' root/.packages/frisbee-1.*.files
		) &
	fi
else
	rm -f etc/init.d/frisbee
fi

###End of residue removal section.


# Allow installer to make frisbee the default network manager.
if Xdialog  --title "Frisbee" --default-no --timeout 60 --ok-label "Yes, set as default" --cancel-label "No" --left --yesno "$(gettext "Frisbee is installed as one of the Connect Wizard network manager options.")\n\n$(gettext "Do you want frisbee to be the default network manager at the next boot-up or\nat the initial boot of a distro package?")" 0 0;then
 echo -e '#!/bin/sh\nexec frisbee' > usr/local/bin/defaultconnect
 sed -i -e '/^frisbee_mode=/ s/=.*/=1/' \
 -e '/^wireless_enabled=/ s/=.*/=1/' \
 -e '/^wireless_autostart=/ s/=.*/=1/' \
 -e '/^announce_state_changes=/ s/=.*/=1/' \
 etc/frisbee/frisbee.conf
 [ -f /etc/dhcpcd_state_notify ] || touch etc/dhcpcd_state_notify
 [ "$(pwd)" = "/" ] && touch /tmp/.frisbee_newly_installed
else
 rm -f etc/dhcpcd_state_notify
fi

#150301 Supply default .conf files only for builds or if absent.
if [ "$(pwd)" != "/" -o ! -f etc/frisbee/dhcpcd.conf ];then
	mv -f etc/frisbee/dhcpcd.tmp etc/frisbee/dhcpcd.conf
	[ "$(ls root/.packages/frisbee-1.*.files 2>/dev/null)" ] \
	 && sed -i 's%\(/etc/frisbee/dhcpcd\.\)tmp%\1conf%' root/.packages/frisbee-1.*.files
else 
	rm -f etc/frisbee/dhcpcd.tmp
	[ "$(ls root/.packages/frisbee-1.*.files 2>/dev/null)" ] \
	 && sed -i '/dhcpcd\.tmp/d' root/.packages/frisbee-1.*.files
fi 
if [ "$(pwd)" != "/" -o ! -f etc/frisbee/frisbee.conf ];then
	mv -f etc/frisbee/frisbee.tmp etc/frisbee/frisbee.conf
	[ "$(ls root/.packages/frisbee-1.*.files 2>/dev/null)" ] \
	 && sed -i 's%\(/etc/frisbee/frisbee\.\)tmp%\1conf%' root/.packages/frisbee-1.*.files
else 
	rm -f etc/frisbee/frisbee.tmp
	[ "$(ls root/.packages/frisbee-1.*.files 2>/dev/null)" ] \
	 && sed -i '/frisbee\.tmp/d' root/.packages/frisbee-1.*.files
fi 
if [ "$(pwd)" != "/" -o ! -f etc/frisbee/wpa_supplicant.conf ];then
	mv -f etc/frisbee/wpa_supplicant.tmp etc/frisbee/wpa_supplicant.conf
	[ "$(ls root/.packages/frisbee-1.*.files 2>/dev/null)" ] \
	 && sed -i 's%\(/etc/frisbee/wpa_supplicant\.\)tmp%\1conf%' root/.packages/frisbee-1.*.files
else 
	rm -f etc/frisbee/wpa_supplicant.tmp
	[ "$(ls root/.packages/frisbee-1.*.files 2>/dev/null)" ] \
	 && sed -i '/wpa_supplicant\.tmp/d' root/.packages/frisbee-1.*.files
fi 

#151227 Install gprs-editable only if not already present...
if [ -f etc/ppp/peers/gprs-editable ];then
 rm -f etc/ppp/peers/gprs-editable.tmp
 sed -i '/gprs-editable\.tmp/d' root/.packages/frisbee-1.*.files
else
 mv -f etc/ppp/peers/gprs-editable.tmp etc/ppp/peers/gprs-editable
 sed -i 's/\(gprs-editable\)\.tmp/\1/' root/.packages/frisbee-1.*.files
fi

#160213 remove files from old locations - for builds, assume updated connectwizard_2nd is present....
if [ "$(pwd)" != "/" ] \
  || grep -q 'frisbee --' usr/sbin/connectwizard;then
 rm -f usr/local/bin/frisbee_mode_disable
 rm -f usr/local/bin/frisbee_cli
 rm -f usr/local/frisbee/connect
 rm -f usr/local/frisbee/disconnect
 sed -i -e '/usr\/local\/bin\/frisbee_mode_disable/d' \
  -e '/usr\/local\/frisbee\/connect/d' \
  -e '/usr\/local\/frisbee\/disconnect/d' \
  root/.packages/frisbee-1.*.files
fi

#Remove old gprs.conf, to generate new one.
rm -f etc/gprs.conf
rm -f root/.config/gprs.conf

#Remove replaced options file, if not used by pgprs.
[ -f usr/sbin/pgprs ] && rm -f etc/ppp/options.gprs
