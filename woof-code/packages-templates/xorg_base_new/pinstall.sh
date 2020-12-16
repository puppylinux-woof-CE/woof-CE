#!/bin/sh

. etc/DISTRO_SPECS

if [ "${DISTRO_TARGETARCH}" != "arm" ]; then
    rm -f usr/share/X11/xorg.conf.d/01-panfrost.conf
fi