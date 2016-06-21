#!/bin/sh
SYSINIT=./etc/rc.d/rc.sysinit
[ -s $SYSINIT ] || exit
grep -q '^[^#]*sfs_load' $SYSINIT && exit
rm -f /tmp/rc.sysinit
sed -e "s,^##*USER SELECTED MODULES,[ -d /initrd ] \&\& [ -x /etc/init.d/sfs_load ] \&\& /etc/init.d/sfs_load start\n\n&," $SYSINIT > /tmp/rc.sysinit
[ -s /tmp/rc.sysinit ] || exit
mv -f $SYSINIT $SYSINIT.org
mv -f /tmp/rc.sysinit $SYSINIT
chmod +x $SYSINIT