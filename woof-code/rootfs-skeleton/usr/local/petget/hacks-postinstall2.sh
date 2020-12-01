#!/bin/sh
#This script inspects the package's installed files and perform some action

PKGFILES="$1"

#pm-utils hack
if [ "$(cat "$PKGFILES" | grep "bin/pm-suspend-hybrid")" != "" ]; then
 for pmsh in $(cat "$PKGFILES" | grep "bin/pm-suspend-hybrid")
 do
 rm -f $pmsh
echo "#!/bin/sh
 exec pm-suspend
" > $pmsh
  chmod +x $pmsh
 done
fi

if [ "$(cat "$PKGFILES" | grep "bin/pm-hibernate")" != "" ]; then
 for pmhib in $(cat "$PKGFILES" | grep "bin/pm-hibernate")
 do
 rm -f $pmhib
echo "#!/bin/sh
 exec pm-suspend
" > $pmhib
  chmod +x $pmhib
 done
fi

#ConsoleKit2 hack
if [ "$(cat "$PKGFILES" | grep "/ConsoleKit/scripts/ck-system-restart")" != "" ]; then

 for flck in $(cat "$PKGFILES" | grep "/ConsoleKit/scripts/ck-system-restart")
 do
 rm -f $flck
 
echo "#!/bin/sh

shutdown_system(){

 . /etc/rc.d/PUPSTATE
 
 if [ \$PUPMODE -eq 5 ]; then 
   shutdownconfig
 elif [ \$PUPMODE -eq 13 ]; then 
   asktosave_session --file
 fi
		
}


#Try for common tools
if [ -x \"/sbin/shutdown\" ] ; then
	shutdown_system
	/sbin/shutdown -r now
	exit \$?
elif [ -x \"/usr/sbin/shutdown\" ] ; then
	shutdown_system
	/usr/sbin/shutdown -r now
	exit \$?
else
	exit 1
fi

" > $flck
  chmod +x $flck
 done
fi


if [ "$(cat "$PKGFILES" | grep "/ConsoleKit/scripts/ck-system-stop")" != "" ]; then

 for flck in $(cat "$PKGFILES" | grep "/ConsoleKit/scripts/ck-system-stop")
 do
 rm -f $flck
 
echo "#!/bin/sh

shutdown_system(){

 . /etc/rc.d/PUPSTATE
 
 if [ \$PUPMODE -eq 5 ]; then 
   shutdownconfig
 elif [ \$PUPMODE -eq 13 ]; then 
   asktosave_session --file
 fi
		
}

#Try for common tools
if [ -x \"/sbin/shutdown\" ]; then
	shutdown_system
	/sbin/shutdown -h now
	exit \$?
elif [ -x \"/usr/sbin/shutdown\" ] ; then
	shutdown_system
	/usr/sbin/shutdown -h now
	exit \$?
else
	exit 1
fi

" > $flck
  chmod +x $flck
 done
fi
