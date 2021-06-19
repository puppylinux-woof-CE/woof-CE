#!/bin/sh
if [ "$(pwd)" = "/" ] && [ -x /etc/init.d/rc.acpi ];then
  export DISPLAY=""	# to simurate startup from rc.sysinit without X
  /etc/init.d/rc.acpi restart
fi