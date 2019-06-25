#!/bin/sh
#basic cache cleaner
#written by mistfire

purge_user(){
xhome="$1"	
rm -rf $xhome/tmp/* 2> /dev/null #...note, not screening this out in any of above save modes.
rm -rf $xhome/.thumbnails/* 2> /dev/null
}

purge_user_cache(){
xhome="$1"
	
for c1 in thumbnails midori google-chrome opera mozilla "moonchild productions" chromium slimjet iron slimjet brave maxthon waterfox vivaldi qupzilla falkon yandex qtweb gnome-web netsurf galeon xombrero kmeleon epiphany vlc wine rhythmbox media-art totem
do
 if [ -d "$xhome/.cache/$c1" ]; then
  rm -rf "$xhome/.cache/$c1"/*
 fi
done

[ -d $xhome/.config/qupzilla/tmp ] && rm -rf $xhome/.config/qupzilla/tmp/*

[ -d $xhome/.gnome2/epiphany/favicon_cache ] && rm -rf $xhome/.gnome2/epiphany/favicon_cache/*
[ -d $xhome/.gnome2/epiphany/mozilla/epiphany/Cache ] && rm -rf $xhome/.gnome2/epiphany/mozilla/epiphany/Cache/*
[ -f $xhome/.gnome2/epiphany/ephy-favicon-cache.xml ] && rm -f $xhome/.gnome2/epiphany/ephy-favicon-cache.xml

[ -d $xhome/.gnome2/rhythmbox/jamendo ] && rm -rf $xhome/.gnome2/rhythmbox/jamendo/*
[ -d $xhome/.gnome2/rhythmbox/magnatune ] && rm -rf $xhome/.gnome2/rhythmbox/magnatune/*

[ -d $xhome/.kde/share/apps/kio_http/cache ] && rm -rf $xhome/.kde/share/apps/kio_http/cache/*
[ -d $xhome/.kde/share/apps/gwenview/recentfolders ] && rm -rf $xhome/.kde/share/apps/gwenview/recentfolders/*rc
[ -d $xhome/.kde/share/apps/gwenview/recenturls ] && rm -rf $xhome/.kde/share/apps/gwenview/recenturls/*rc
[ -d $xhome/.kde/share/apps/RecentDocuments ] && rm -rf $xhome/.kde/share/apps/RecentDocuments/*.desktop
  
rm -rf $xhome/.kde/cache-* 2> /dev/null
rm -rf $xhome/.kde/tmp-* 2> /dev/null

for kdever in 2 3 4 5 6 7 8 9 10
do
  [ -d $xhome/.kde$kdever/share/apps/kio_http/cache ] && rm -rf $xhome/.kde$kdever/share/apps/kio_http/cache/*
  [ -d $xhome/.kde$kdever/share/apps/gwenview/recentfolders ] && rm -rf $xhome/.kde$kdever/share/apps/gwenview/recentfolders/*rc
  [ -d $xhome/.kde$kdever/share/apps/gwenview/recenturls ] && rm -rf $xhome/.kde$kdever/share/apps/gwenview/recenturls/*rc
  [ -d $xhome/.kde$kdever/share/apps/RecentDocuments ] && rm -rf $xhome/.kde$kdever/share/apps/RecentDocuments/*.desktop
  
  rm -rf $xhome/.kde$kdever/cache-* 2> /dev/null
  rm -rf $xhome/.kde$kdever/tmp-* 2> /dev/null
done

for lofver in 1 2 3 4 5 6 7 8 9 10
do
 [ -d $xhome/.config/libreoffice/$lofver/user/uno_packages/cache ] && rm -rf $xhome/.config/libreoffice/$lofver/user/uno_packages/cache/*
 [ -d $xhome/.config/libreoffice/${lofver}-suse/user/uno_packages/cache ] && rm -rf $xhome/.config/libreoffice/${lofver}-suse/user/uno_packages/cache/*
 [ -d $xhome/.libreoffice/$lofver/user/uno_packages/cache ] && rm -rf $xhome/.libreoffice/$lofver/user/uno_packages/cache/* 
 [ -d $xhome/.libreoffice/${lofver}-suse/user/uno_packages/cache ] && rm -rf $xhome/.libreoffice/${lofver}-suse/user/uno_packages/cache/* 
done

if [ -d $xhome/.opera ]; then
 rm -rf $xhome/.opera/cache* 2>/dev/null
 [ -d $xhome/.opera/opcache ] && rm -rf $xhome/.opera/opcache/*
 [ -d $xhome/.opera/thumbnails ] && rm -rf $xhome/.opera/thumbnails/*
 [ -d $xhome/.opera/icons ] && rm -rf $xhome/.opera/icons/*
fi

 [ -d $xhome/.wine/drive_c/windows/temp ] && rm -rf $xhome/.wine/drive_c/windows/temp/*
 [ -d $xhome/.wine/drive_c/winetrickstmp ] && rm -rf $xhome/.wine/drive_c/winetrickstmp/*
 [ -d $xhome/.winetrickscache ] && rm -rf $xhome/.winetrickscache/*

 [ -d $xhome/.aMule/Temp ] && rm -rf $xhome/.aMule/Temp/*
 
 [ -d $xhome/.adobe/Flash_Player/AssetCache ] && rm -rf $xhome/.adobe/Flash_Player/AssetCache/*
 [ -d $xhome/.adobe/Flash_Player/NativeCache ] && rm -rf $xhome/.adobe/Flash_Player/NativeCache/*

 [ -d $xhome/.config/audacious/thumbs ] && rm -rf $xhome/.config/audacious/thumbs/*
 [ -d $xhome/.config/audacious/log ] && rm -rf $xhome/.config/audacious/log/*
 
 [ -d $xhome/.java/deployment/cache ] && rm -rf $xhome/.java/deployment/cache/*
 [ -d $xhome/.icedteaplugin/cache ] && rm -rf $xhome/.icedteaplugin/cache/*
 [ -d $xhome/.icedtea/cache ] && rm -rf $xhome/.icedtea/cache/*

 [ -d $xhome/.icedtea/cache ] && rm -rf $xhome/.icedtea/cache/*

 [ -d $xhome/.beagle/TextCache ] && rm -rf $xhome/.beagle/TextCache/*
 [ -d $xhome/.beagle/Indexes ] && rm -rf $xhome/.beagle/Indexes/*
 [ -d $xhome/.beagle/Log ] && rm -rf $xhome/.beagle/Log/*
 
 [ -d $xhome/.anydesk/thumbnails ] && rm -rf $xhome/.anydesk/thumbnails/*
 
 [ -d $xhome/.xchat2/scrollback ] && rm -rf $xhome/.xchat2/scrollback/*
 [ -d $xhome/.xchat2/logs ] && rm -rf $xhome/.xchat2/logs/*
 [ -d $xhome/.xchat2/chatlogs ] && rm -rf $xhome/.xchat2/chatlogs/*

 [ -d $xhome/.googleearth/Cache ] && rm -rf $xhome/.googleearth/Cache/*
 [ -d $xhome/.googleearth/Temp ] && rm -rf $xhome/.googleearth/Temp/*

 
}

pre_cleanup(){		
#when the working files run in tmpfs in ram, they are saved (below) and /tmp and /var
#are screened out. however, some PUPMODES mount ${DISTRO_FILE_PREFIX}save.2fs directly on /initrd/pup_rw,
#the top aufs layer, meaning that there is no intermediary tmpfs in ram for working
#files, hence everything is saved directly, ditto for PUPMODE=2 a full h.d. install.
#hence need to do some explicit wiping here...

croot="$1"

echo "Cleaning up. Please wait..."

rm -f $croot/tmp/xerrs.log 2>/dev/null
rm -f $croot/tmp/udevtrace*.log 2>/dev/null
rm -f $croot/tmp/bootkernel.log 2>/dev/null
rm -rf $croot/tmp/pup_event_backend/* 2>/dev/null

echo -n "" > $croot/var/log/messages #delete, as it keeps growing.(note choosepartfunc uses this)
rm -f $croot/var/log/messages.* 2>/dev/null
rm -rf $croot/var/log/cups/* 2>/dev/null
rm -rf $croot/var/log/samba/* 2>/dev/null

echo "Performing cleanup at $croot/root ..."
purge_user "$croot/root"
purge_user_cache "$croot/root"

if [ -d $croot/home ]; then
USERLIST=`find $croot/home -maxdepth 1 -mindepth 1 -type d | rev | cut -f 1 -d '/' | rev`

	if [ "$USERLIST" != "" ]; then
		for USERNAME in $USERLIST
		do
		 echo "Performing cleanup at $croot/home/$USERNAME ..."
		 purge_user "$croot/home/$USERNAME"
         purge_user_cache "$croot/home/$USERNAME"
		done
	fi
fi

echo "Cleanup complete!"
	
}

pre_cleanup "$1"
