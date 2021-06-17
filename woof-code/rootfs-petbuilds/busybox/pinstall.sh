#!/bin/sh

# prevent collision with acpid-busybox PET
[ -e etc/init.d/rc.acpi ] && rm -f etc/xdg/autostart/acpid.desktop
